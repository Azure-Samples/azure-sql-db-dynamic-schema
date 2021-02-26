delete from dbo.[todo_json];
go

declare @t nvarchar(max) = '{
	"title": "test",
	"completed": 0,
	"order": 1,
	"createdOn": "2020-10-25 10:00:00"	
}';
insert into dbo.todo_json (todo) values (@t)
go

declare @t2 nvarchar(max) = '{
	"title": "another test",
	"completed": 1,
	"order": 2,
	"createdOn": "2020-10-24 22:00:00"		
}';
insert into dbo.todo_json (todo) values (@t2)
go

select * from dbo.[todo_json]
go

/*
	GET
*/
exec web.get_todo_json '{"id": 58}'
go


/*
	POST
*/
declare @j nvarchar(max) = '{
	"title": "hello again!",
	"completed": 1,
	"order": 2,
	"createdOn": "2020-10-28 10:00:00"	
}';

exec web.post_todo_json @j
go

/*
	PATCH
*/
declare @j nvarchar(max) = '{
	"id": 60,
	"todo":	{
		"title": "hello again, patched!",
		"completed": 1,
		"order": 42
	}
}';

exec web.patch_todo_json @j
go

select * from dbo.todo_json
go

alter table dbo.[todo_json]
add [Title] as json_value([todo], '$.title') persisted
go

select * from dbo.todo_json
go
