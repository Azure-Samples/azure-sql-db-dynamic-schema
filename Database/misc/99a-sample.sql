drop table if exists dbo.todo_sample;
go

create table dbo.todo_sample
(
	id int not null primary key default (next value for [global_sequence]),
	todo nvarchar(100) not null,
	completed tinyint not null default (0)
)
go

insert into 
	dbo.todo_sample (todo, completed)
values 
	('say hello world', 1),
	('say it again', 0)
go

select * from dbo.[todo_sample]
go

create or alter procedure web.get_todo_sample_classic
@id int
as
begin 
	select 
		Id, 
		todo as Title, 
		cast(completed as bit) as Completed		
	from 
		dbo.[todo_sample] 
	where 
		id = @id
end
go

create or alter procedure web.get_todo_sample_json
@id int
as
begin
	select 
		id, 
		todo as title, 
		cast(completed as bit) as completed		
	from 
		dbo.[todo_sample] 
	where 
		id = @id
	for json auto, without_array_wrapper
end
go

alter table dbo.[todo_sample]
add [order] int null
go

/* --> Remember! Add Column Speed Test */

insert into 
	dbo.todo_sample (todo, completed, [order])
values 
	('stay in the line!', 0, 1)
go

select * from dbo.[todo_sample]
go

create or alter procedure web.get_todo_sample_json
@id int
as
begin
	select 
		id, 
		todo as title, 
		cast(completed as bit) as completed,
        [order]
	from 
		dbo.[todo_sample] 
	where 
		id = @id
	for json auto, without_array_wrapper
end
go

declare @j nvarchar(max) = '[{"id":1}, {"id":5}]';
select * from openjson(@j) with (id int)
go

create or alter procedure web.get_todo_sample_json2
@payload nvarchar(max)
as
begin
	if (isjson(@payload) <> 1) begin;
		throw 50000, 'Payload is not a valid JSON document', 16;
	end

	select
		id,
		todo as title,
		cast(completed as bit) as completed,
        [order]
	from
		dbo.todo_sample t
	where
		exists (select p.id from openjson(@payload) with (id int) as p where p.id = t.id)
	for json auto;
end
go

declare @j nvarchar(max) = '[{"id":1}, {"id":5}]';
exec web.get_todo_sample_json2 @j
go

/*
https://github.com/yorek/azure-sql-db-samples/tree/master/samples/07-network-latency
*/