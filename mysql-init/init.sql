use ofoody;

create table if not exists USERS
    ( id integer primary key auto_increment
    , username text not null
    , review text
    , ccn text not null
    , address text not null
    , password text not null
    );

insert into USERS (username, review, ccn, address, password) values
    ( 'Cookie Monster'
    , 'Om nom nom nom'
    , '734b12fac1c2875367114a1d42730610'
    , 'The Dark Side of the Moon'
    , 'my_very_secure_password'
    );
