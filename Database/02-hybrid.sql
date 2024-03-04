drop table if exists [dbo].[todo_hybrid];
create table [dbo].[todo_hybrid]
(
	[id] [int] not null,
	[todo] [nvarchar](100) not null,
	[completed] [tinyint] not null,
	[extension] nvarchar(max) null,
)
go
alter table [dbo].[todo_hybrid] add constraint pk__todo_hybrid primary key clustered ([id] asc) with (optimize_for_sequential_key = on)
go
alter table [dbo].[todo_hybrid] add constraint df__todo_hybrid__id default (next value for [global_sequence]) for [id]
go
alter table [dbo].[todo_hybrid] add constraint df__todo_hybrid__completed default ((0)) for [completed]
go
alter table [dbo].[todo_hybrid] add constraint ck__todo_hybrid__other check (isjson([extension]) = 1)
go

/*
	GET
*/
create or alter procedure [web].[get_todo_hybrid]
@payload nvarchar(max) = null
as
begin

-- return all
if (@payload = '' or @payload is null) begin;	
	/*
		With SQL Server 2022 & Azure SQL
	*/
	/*
	select
		json_object('id':id, 'title':todo, 'completed':cast(completed as bit)),
		json_query(extension) as extension
	from 
		dbo.[todo_hybrid] as o
	*/
	select 
		json_query((select id, todo as title, cast(completed as bit) as completed from dbo.todo_hybrid as i where o.id = i.id for json auto, without_array_wrapper)) as todo,
		json_query(extension) as extension
	from 
		dbo.[todo_hybrid] as o
	return;
end;

-- return the specified todos
if (isjson(@payload) <> 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

select 
	json_query((select id, todo as title, cast(completed as bit) as completed from dbo.todo_hybrid as i where o.id = i.id for json auto, without_array_wrapper)) as todo,
	json_query(extension) as extension
from 
	dbo.[todo_hybrid] as o
where
	exists (select p.id from openjson(@payload) with (id int) as p where p.id = o.id)
end;
go


/*
	POST
*/
create or alter procedure [web].[post_todo_hybrid]
@payload nvarchar(max)
as
if (isjson(@payload) != 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

declare @ids table (id int not null);

insert into dbo.todo_hybrid ([todo], [completed], [extension])
output inserted.id into @ids
select [title], isnull([completed],0), extension from openjson(@payload) with
(
	title nvarchar(100),
	completed bit,
	extension nvarchar(max) as json
)

declare @newPayload as nvarchar(max) = (select id from @ids for json auto);
exec [web].[get_todo_hybrid] @newPayload;
go


/*
PATCH
*/
create or alter procedure [web].[patch_todo_hybrid]
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
		title,
		completed,
		extension
	from 
		openjson(@payload) with
		(
			id int '$.id',
			todo nvarchar(max) as json
		) 
		cross apply openjson(todo) with 
		(
			new_id int '$.id',
			title nvarchar(100),
			completed bit,
			extension nvarchar(max) as json
		)
)
update
	t
set
	id = coalesce(c.new_id, t.id),
	todo = coalesce(c.title, t.todo),
	completed = coalesce(c.completed, t.completed),
	extension = coalesce(c.extension, t.extension)
output 
	inserted.id into @ids
from
	dbo.[todo_hybrid] t
inner join
	cte c on t.id = c.id
;

declare @newPayload as nvarchar(max) = (select id from @ids for json auto);
exec [web].[get_todo_hybrid] @newPayload
go

/*
	DELETE
*/
create or alter procedure [web].[delete_todo_hybrid]
@payload nvarchar(max) = null
as
begin

-- delete all
if (@payload = '' or @payload is null) begin;
	delete from dbo.[todo_hybrid];
	return;
end

-- return the specified todos
if (isjson(@payload) <> 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

delete t from dbo.todo_hybrid t 
where exists (select p.id from openjson(@payload) with (id int) as p where p.id = t.id)

end
