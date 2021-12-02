/*
	Classic
*/
insert into 
	dbo.todo_classic (id, todo, completed)
values 
	(1, 'say hello world', 1),
	(2, 'say it again', 0)
go

exec web.[post_todo_classic] '{"title": "hello from here too"}'
exec web.[post_todo_classic] '{"title": "yep, hello!", "completed": true}'
go

select * from dbo.[todo_classic]
go

exec [web].[get_todo_classic] '{"id":1}';
go

/*
	Hybrid
*/
insert into 
	dbo.todo_hybrid (id, todo, completed, extension)
values 
	(1, 'say hello world', 1, '{"priority":"high","category":"work"}'),
	(2, 'say it again', 0, '{"priority":"high","color":"yellow"}')
go

exec web.[post_todo_hybrid] '{"title": "hello from here too"}'
exec web.[post_todo_hybrid] '{"title": "yep, hello!", "completed": true, "extension": {"priority":"high","color":"orange"}}'
go

select * from dbo.[todo_hybrid]
go

exec [web].[get_todo_hybrid] '{"id":1}';
go

/*
	Document
*/

insert into 
	dbo.todo_document (id, todo)
values 
	(1, '{"title": "say hello world", "completed": 1, "order": 2, "createdOn": "2020-10-24 22:00:00"}'),
	(2, '{"title": "say it again", "completed": 0, "priority":"high","color":"yellow"}')
go


exec web.[post_todo_document] '{"title": "hello from here too"}'
exec web.[post_todo_document] '{"title": "yep, hello!", "completed": true, "priority":"high","color":"orange"}'
go

select * from dbo.[todo_document]
go

exec [web].[get_todo_document] '{"id":1}';
go

/*
	Go to the extreme end, just having one "document" column, 
	and then create the "id" column as a calculated column.
	Also add needed indexes to have good performance.
*/

select * into dbo.todo_document_2 from dbo.[todo_document]
go

select * from dbo.[todo_document_2]
go

update  dbo.[todo_document_2] set todo = json_modify(todo, '$.id', id)
go

alter table dbo.[todo_document_2]
drop column id
go

alter table dbo.[todo_document_2]
add id as cast(json_value(todo, '$.id') as int) 
go

alter table dbo.[todo_document_2]
add constraint pk unique clustered (id)
go

select * from dbo.[todo_document_2]
go

insert into dbo.todo_document_2 (todo) 
values ('{"title": "still works nicely!","id":987}')
go

select * from dbo.[todo_document_2]
go

