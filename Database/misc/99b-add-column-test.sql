drop table if exists dbo.todo_test;
go

create table dbo.todo_test
(
	id int not null primary key default (next value for [global_sequence]),
	todo nvarchar(100) not null,
	completed tinyint not null default (0),
	[order] int null
)
go

grant select on dbo.todo_test to [dynamic-schema-test-user]
go

with cte as
(
	select top (1000000) n = row_number() over (order by a.[object_id]) from sys.[all_columns] a, sys.[all_columns] b 
)
insert into
	dbo.[todo_test]
select
	n as id,
	'Todo Test ' + cast(n as nvarchar(10)) as todo,
	0 as completed,
	n as [order]
from
	cte
;

select format(count(*), 'n') from dbo.[todo_test];
go

select top (10) * from dbo.[todo_test];
go

-- Run SQLQueryStress with this query
select top (10) * from dbo.[todo_test] where id >= cast(rand() * 1000000 as int)
GO

alter table dbo.[todo_test] 
add createdOn datetime2 null
go

select top (10) * from dbo.[todo_test];
go

-- Index JSON sample

select top (10) * from dbo.[todo_test] where id >= cast(rand() * 10000000 as int)
go

alter table dbo.[todo_test] 
add extension nvarchar(max) null 
go

update dbo.[todo_test] set extension = '{"author": "John Doe", "date": "2019-01-01"}' where id = 707149
go

alter table dbo.[todo_test] 
add author as json_value(extension, '$.author') 
go

select top (10) * from dbo.[todo_test] where id between 707145 and 707150
go

--dbcc dropcleanbuffers
select top (10) * from dbo.[todo_test] 
where json_value(extension, '$.author') = 'John Doe'
go

create nonclustered index ix1 on dbo.[todo_test] (author)
where extension is not null
--with drop_existing
go

select top (10) * from dbo.[todo_test] 
where json_value(extension, '$.author') = 'John Doe' 
and extension is not null
go
