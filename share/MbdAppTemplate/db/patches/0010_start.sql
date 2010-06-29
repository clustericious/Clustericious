%% my $class = shift;
-- Put database schema here

create table clustericious (
    app varchar primary key,
    version varchar
    );

insert into clustericious (app,version)
    values ( '<%%= $class %%>', '0.01' );

