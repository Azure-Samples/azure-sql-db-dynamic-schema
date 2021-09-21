drop table if exists [dbo].[todo_document];
create table [dbo].[todo_document]
(
	[id] [int] not null,
	[todo] nvarchar(max) null,
)
go
alter table [dbo].[todo_document] add constraint pk__todo_document primary key clustered ([id] asc) with (optimize_for_sequential_key = on)
go
alter table [dbo].[todo_document] add constraint df__todo_document__id default (next value for [global_sequence]) for [id]
go
alter table [dbo].[todo_document] add constraint ck__todo_document__todo check (isjson([todo]) = 1)
go

/*
	GET
*/
create or alter procedure [web].[get_todo_document]
@payload nvarchar(max) = null
as
begin

-- return all
if (@payload = '' or @payload is null) begin;
	select 
		json_modify([todo], '$.id', id) as todo
	from 
		dbo.[todo_document]
	return;
end;

-- return the specified todos
if (isjson(@payload) <> 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

select 
	json_modify([todo], '$.id', id) as todo
from 
	dbo.[todo_document] t
where
	exists (select p.id from openjson(@payload) with (id int) as p where p.id = t.id)

end;
go

/*
	POST
*/
create or alter procedure [web].[post_todo_document]
@payload nvarchar(max)
as
if (isjson(@payload) != 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

declare @ids table (id int not null);

insert into dbo.todo_document ([todo])
output inserted.id into @ids
select [value] from openjson(@payload) where [type] = 5 -- split array into multiple rows

if (@@rowcount=0) begin
	insert into dbo.todo_document ([todo])
	output inserted.id into @ids
	values (@payload)
end

declare @newPayload as nvarchar(max) = (select id from @ids for json auto);
exec [web].[get_todo_document] @newPayload;
go

/*
	PATCH
*/
create or alter procedure [web].[patch_todo_document]
@payload nvarchar(max)
as
if (isjson(@payload) <> 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

declare @ids table (id int not null);

with cte as
(
	select 
		id,
		new_id,
		[todo]
	from 
		openjson(@payload) with
		(
			id int '$.id',
			new_id int '$.todo.id',
			todo nvarchar(max) as json
		) 
)
update
	t
set
	id = coalesce(c.new_id, t.id),
	todo = coalesce(c.[todo], t.todo)
output 
	inserted.id into @ids
from
	dbo.[todo_document] t
inner join
	cte c on t.id = c.id
;

declare @newPayload as nvarchar(max) = (select id from @ids for json auto);
exec [web].[get_todo_document] @newPayload
go

/*
	DELETE
*/
create or alter procedure [web].[delete_todo_document]
@payload nvarchar(max) = null
as
begin

-- delete all
if (@payload = '' or @payload is null) begin;
	delete from dbo.[todo_document];
	return;
end

-- return the specified todos
if (isjson(@payload) <> 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

delete t from dbo.todo_document t 
where exists (select p.id from openjson(@payload) with (id int) as p where p.id = t.id)

end