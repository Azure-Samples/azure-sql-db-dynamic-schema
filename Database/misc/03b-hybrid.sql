delete from dbo.[todo_hybrid];
go

declare @t nvarchar(max) = '{
	"title": "test",
	"completed": 0,
	"extension": {
		"order": 1,
		"createdOn": "2020-10-25 10:00:00"	
	}
}';

insert into 
	dbo.[todo_hybrid] (todo, completed, [extension])
select
	title,
	completed,
	[extension]
from
	openjson(@t) with 
	(
		title nvarchar(100) '$.title',
		completed bit '$.completed',
		[extension] nvarchar(max) '$.extension' as json
	)
go

declare @t2 nvarchar(max) = '{
	"title": "another test",
	"completed": 1,
	"extension": {
		"order": 2,
		"createdOn": "2020-10-24 22:00:00"	
	}
}';

insert into 
	dbo.[todo_hybrid] (todo, completed, [extension])
select
	title,
	completed,
	[extension]
from
	openjson(@t2) with 
	(
		title nvarchar(100) '$.title',
		completed bit '$.completed',
		[extension] nvarchar(max) '$.extension' as json
	)
go

select * from dbo.[todo_hybrid]
go

/*
	GET
*/
exec web.get_todo_hybrid '{"id": 50}'
go

/*
	POST
*/
declare @j nvarchar(max) = '{
	"title": "hello again!",
	"completed": 1,
	"extension": {
		"order": 2,
		"createdOn": "2020-10-28 10:00:00"	
	}
}';

exec web.post_todo_hybrid @j

/*
	PATCH
*/
declare @j nvarchar(max) = '{
	"id": 52,
	"todo":	{
		"title": "hello again, with patches!",
		"extension": {
			"order": 42
		}
	}
}';

exec web.patch_todo_hybrid @j
go