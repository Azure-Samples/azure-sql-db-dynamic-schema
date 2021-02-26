drop table if exists [dbo].[todo_classic];
create table [dbo].[todo_classic]
(
	[id] [int] not null,
	[todo] [nvarchar](100) not null,
	[completed] [tinyint] not null
)
go
alter table [dbo].[todo_classic] add constraint pk__todo_classic primary key clustered ([id] asc) with (optimize_for_sequential_key = on)
go
alter table [dbo].[todo_classic] add constraint df__todo_classic__id default (next value for [global_sequence]) for [id]
go
alter table [dbo].[todo_classic] add constraint df__todo_classic__completed default ((0)) for [completed]
go

/*
	GET
	Accepted Input: 
	''
	'[{"id":1}, {"id":2}]'
*/
create or alter procedure [web].[get_todo_classic]
@payload nvarchar(max) = null
as
begin

-- return all
if (@payload = '' or @payload is null) begin;
select 
	cast(
		(select
			id,
			todo as title,
			cast(completed as bit) as completed
		from
			dbo.todo_classic t
		for json path)
	as nvarchar(max)) as result;
	return;
end;

-- return the specified todos
if (isjson(@payload) <> 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

select 
	cast(
		(select
			id,
			todo as title,
			cast(completed as bit) as completed
		from
			dbo.todo_classic t
		where
			exists (select p.id from openjson(@payload) with (id int) as p where p.id = t.id)
		for json path, without_array_wrapper)
	as nvarchar(max)) as result
end;
go

/*
	POST
	Accepted Input: 
	'[{"id":1, "title":"todo title", "completed": 0}, {"id":2, "title": "another todo"}]'
*/
create or alter procedure [web].[post_todo_classic]
@payload nvarchar(max)
as
if (isjson(@payload) != 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

declare @ids table (id int not null);

insert into dbo.todo_classic ([todo], [completed])
output inserted.id into @ids
select [title], isnull([completed],0) from openjson(@payload) with
(
	title nvarchar(100),
	completed bit
)

declare @newPayload as nvarchar(max) = (select id from @ids for json auto);
exec [web].[get_todo_classic] @newPayload;
go

/*
	PATCH
	Accepted Input: 
	'[{"id":1, "todo":{"id": 10, "title": "updated title", "completed": 1 },{...}]'
*/
create or alter procedure [web].[patch_todo_classic]
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
		completed
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
			completed bit
		)
)
update
	t
set
	id = coalesce(c.new_id, t.id),
	todo = coalesce(c.title, t.todo),
	completed = coalesce(c.completed, t.completed)
output 
	inserted.id into @ids
from
	dbo.[todo_classic] t
inner join
	cte c on t.id = c.id
;

declare @newPayload as nvarchar(max) = (select id from @ids for json auto);
exec [web].[get_todo_classic] @newPayload
go

/*
	DELETE
	Accepted Input: 
	'[{"id":1}, {"id":2}]'
*/
create or alter procedure [web].[delete_todo_classic]
@payload nvarchar(max) = null
as
begin

-- delete all
if (@payload = '' or @payload is null) begin;
	delete from dbo.[todo_classic];
	return;
end

-- return the specified todos
if (isjson(@payload) <> 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

delete t from dbo.todo_classic t 
where exists (select p.id from openjson(@payload) with (id int) as p where p.id = t.id)

end