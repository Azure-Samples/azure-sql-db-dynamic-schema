delete from dbo.[todo_classic];
go

declare @t nvarchar(max) = '{
	"title": "test",
	"completed": 0	
}';

insert into 
	dbo.[todo_classic] (todo, completed)
select
	title,
	completed,
	[order]
from
	openjson(@t) with 
	(
		title nvarchar(100) '$.title',
		completed bit '$.completed'
	)
go

declare @t2 nvarchar(max) = '{
	"title": "another test",
	"completed": 1
}';

insert into 
	dbo.[todo_classic] (todo, completed)
select
	title,
	completed,
	[order]
from
	openjson(@t2) with 
	(
		title nvarchar(100) '$.title',
		completed bit '$.completed'
	)
go

select * from dbo.[todo_classic]
go

/*
	GET
*/
exec web.get_todo_classic '{"id": 55}'
go

/*
	POST
*/
declare @j nvarchar(max) = '{
	"title": "hello again!",
	"completed": 1
}';

exec web.post_todo_classic @j

/*
	PATCH
*/
declare @j nvarchar(max) = '{
	"id": 57,
	"todo":	{
		"title": "hello again, with patches!"
	}
}';

exec web.patch_todo_classic @j
go