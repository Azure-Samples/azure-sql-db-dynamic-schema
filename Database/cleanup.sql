drop table if exists dbo.[todo_classic];
drop table if exists dbo.[todo_hybrid];
drop table if exists dbo.[todo_json];
drop table if exists dbo.[todo_sample];
drop table if exists dbo.[todo_test];

drop sequence if exists dbo.[global_sequence];

drop procedure if exists web.[get_todo_classic];
drop procedure if exists web.[get_todo_hybrid];
drop procedure if exists web.[get_todo_json];

drop procedure if exists web.[post_todo_classic];
drop procedure if exists web.[post_todo_hybrid];
drop procedure if exists web.[post_todo_json];

drop procedure if exists web.[patch_todo_classic];
drop procedure if exists web.[patch_todo_hybrid];
drop procedure if exists web.[patch_todo_json];

drop procedure if exists web.[delete_todo_classic];
drop procedure if exists web.[delete_todo_hybrid];
drop procedure if exists web.[delete_todo_json];

drop procedure if exists web.[get_todo_sample_classic];
drop procedure if exists web.[get_todo_sample_json];
drop procedure if exists web.[get_todo_sample_json2];