create schema [web] authorization [dbo];
go

create user [dynamic-schema-test-user] with password = 'Super_Str0ng*P@ZZword!'
go

grant execute on schema::[web] to [dynamic-schema-test-user]
go

create sequence dbo.[global_sequence]
as int
start with 1
increment by 1;
go

