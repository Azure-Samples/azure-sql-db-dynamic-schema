/*
	GET
	Accepted Input: 
	'[{"id":1}, {"id":2}]' or '{"id":1}'
*/
create or alter procedure [web].[get_todo_test_classic]
@payload nvarchar(max) = null
as
begin
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

create or alter procedure [web].[get_todo_test_hybrid]
@payload nvarchar(max) = null
as
begin
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

create or alter procedure [web].[get_todo_test_document]
@payload nvarchar(max) = null
as
begin
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


insert into 
	dbo.todo_classic (id, todo, completed)
values 
	(1, 'say hello world', 1),
	(2, 'say it again', 0)
go

exec [web].[get_todo_test_classic] '{"id":1}';
go

insert into 
	dbo.todo_hybrid (id, todo, completed, extension)
values 
	(1, 'say hello world', 1, '{"priority":"high","category":"work"}'),
	(2, 'say it again', 0, '{"priority":"high","color":"yellow"}')
go

exec [web].[get_todo_test_hybrid] '{"id":1}';
go

insert into 
	dbo.todo_document (id, todo)
values 
	(1, '{"title": "say hello world", "completed": 1, "order": 2, "createdOn": "2020-10-24 22:00:00"}'),
	(2, '{"title": "say it again", "completed": 0, "priority":"high","color":"yellow"}')
go

exec [web].[get_todo_test_document] '{"id":1}';
go