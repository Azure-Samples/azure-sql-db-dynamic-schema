--/*
--	Add new column
--*/
alter table [dbo].[todo_classic] 
add [order] int null
go

/*
	GET
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
			cast(completed as bit) as completed,
			[order]
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
			cast(completed as bit) as completed,
			[order]
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
*/
create or alter procedure [web].[post_todo_classic]
@payload nvarchar(max)
as
if (isjson(@payload) != 1) begin;
	throw 50000, 'Payload is not a valid JSON document', 16;
end;

declare @ids table (id int not null);

insert into dbo.todo_classic ([todo], [completed], [order])
output inserted.id into @ids
select [title], isnull([completed],0), [order] from openjson(@payload) with
(
	title nvarchar(100),
	completed bit,
	[order] int
)

declare @newPayload as nvarchar(max) = (select id from @ids for json auto);
exec [web].[get_todo_classic] @newPayload;
go

/*
PATCH
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
		completed,
		[order]
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
			[order] int
		)
)
update
	t
set
	id = coalesce(c.new_id, t.id),
	todo = coalesce(c.title, t.todo),
	completed = coalesce(c.completed, t.completed),
	[order] = coalesce(c.[order], t.[order])
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
