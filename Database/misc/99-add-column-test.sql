drop table if exists dbo.todo_test;
go

select * into dbo.todo_test from dbo.todo_sample;
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

select top (10) * from dbo.[todo_test];
go

alter table dbo.[todo_test] 
add createdOn datetime2 null
go


