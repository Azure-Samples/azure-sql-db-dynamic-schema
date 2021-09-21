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

alter table dbo.[todo_test] 
add createdOn datetime2 null
go

select top (10) * from dbo.[todo_test];
go


