DELETE FROM api_table_view WHERE solution_id=10000;
DELETE FROM api_event_handler WHERE solution_id=10000;

INSERT IGNORE INTO api_solution(id,name) VALUES (10000, 'IoTSensorNet');


CREATE TABLE IF NOT EXISTS iot_node (
    id int NOT NULL,
    name varchar(250) NOT NULL,
    last_error_code int NULL,
    ip_address varchar(50) NULL,
    last_heard_on timestamp NULL,
    PRIMARY KEY(id),
    INDEX(name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS iot_sensor_data(
    id int NOT NULL AUTO_INCREMENT,
    sensor_id varchar(250) NOT NULL,
    sensor_namespace varchar(500) NOT NULL,
    sensor_value numeric(15,4) NOT NULL,
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS iot_sensor (
    id varchar(250) NOT NULL COMMENT 'unique id',
    alias varchar(250) NOT NULL COMMENT 'sensor_id',
    description varchar(250) NOT NULL,
    unit varchar(50) NOT NULL default 'unit',
    days_in_history int NOT NULL default '0' COMMENT 'auto delete in days',
    auto_delete_sensor_data smallint NOT NULL default '0' COMMENT '0=yes -1=no',
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS iot_sensor_routing_status(
    id int NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_sensor_routing_status(id, name) VALUES (0,'New');
INSERT IGNORE INTO iot_sensor_routing_status(id, name) VALUES (10,'Active');
INSERT IGNORE INTO iot_sensor_routing_status(id, name) VALUES (20,'Disabled');


CREATE TABLE IF NOT EXISTS iot_sensor_routing (
    id int NOT NULL AUTO_INCREMENT COMMENT 'unique id',
    internal_sensor_id varchar(250) NULL COMMENT 'sensorid for internal use',
    external_sensor_id varchar(250) NOT NULL COMMENT 'sensor id from a foreign network',
    description varchar(50) NULL COMMENT 'description for this assignment',
    status_id int NOT NULL default '0' COMMENT '0=new 1=enabled',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    last_value_on timestamp NULL,
    PRIMARY KEY(id),
    UNIQUE KEY(external_sensor_id),
    FOREIGN KEY(status_id) REFERENCES iot_sensor_routing_status(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS iot_log_source (
    id int NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_log_source(id,name) VALUES (1,'Node');
INSERT IGNORE INTO iot_log_source(id,name) VALUES (2,'Node (Serial Debug)');
INSERT IGNORE INTO iot_log_source(id,name) VALUES (100,'System');

CREATE TABLE IF NOT EXISTS iot_log (
    id int NOT NULL AUTO_INCREMENT,
    name varchar(250) NOT NULL,
    message text NULL,
    source_id int NOT NULL,
    node_id int NULL COMMENT 'in case of source_id=1',
    node_name varchar(250) NULL COMMENT 'in case of source_id=1',
    ip_address varchar(50) NULL COMMENT 'in case of source_id=1',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(source_id) REFERENCES iot_log_source(id),
    FOREIGN KEY(node_id) REFERENCES iot_node(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


INSERT IGNORE INTO api_user (id,username,password,is_admin,disabled,solution_id) VALUES (10000,'IoTSrv','password',0,0,10000);
INSERT IGNORE INTO api_user (id,username,password,is_admin,disabled,solution_id) VALUES (10001,'IoTAdmin','password',0,-1,10000);

INSERT IGNORE INTO api_group(id,groupname,solution_id) VALUES (10000,'IoTSensorNetworkSrv',10000);
INSERT IGNORE INTO api_group(id,groupname,solution_id) VALUES (10001,'IoTSensorNetworkAdmin',10000);

INSERT IGNORE INTO api_user_group(user_id,group_id,solution_id) VALUES (10000,10000,10000);
INSERT IGNORE INTO api_user_group(user_id,group_id,solution_id) VALUES (10001,10001,10000);


INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10000,'iot_sensor_data','iot_sensor_data','id','int','sensor_value',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10001,'iot_sensor','iot_sensor','id','int','description',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10002,'iot_sensor_routing','iot_sensor_routing','id','int','description',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10003,'iot_sensor_routing_status','iot_sensor_routing_status','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10004,'iot_log_source','iot_log_source','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10005,'iot_log','iot_log','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10006,'iot_node','iot_node','id','int','name',10000);


INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10000,-1,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10001,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10002,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10003,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10004,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10005,-1,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10006,0,-1,0,10000);



/* Admin */
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10000,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10001,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10002,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10003,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10004,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10005,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10006,-1,-1,-1,-1,10000);



INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES ('iot_sensor_routing','iot_sensor_data','insert','before',90,10000);

INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES ('iot_setlast_value','iot_sensor_data','insert','before',100,10000);

INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES ('iot_set_node_status','iot_log','insert','before',100,10000);

/* Listviews */
INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10001,'LISTVIEW','default',10001,'id',10000,'<restapi type="select">
    <table name="iot_sensor" alias="s"/>
    <filter type="or">
        <condition field="description" table_alias="s" value="$$query$$" operator=" like "/>
        <condition field="alias" table_alias="s" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="last_value_on" alias="s" sort="DESC"/>
    </orderby>
    <select>
        <field name="id" table_alias="s" alias="id"/>
        <field name="description" table_alias="s"/>
        <field name="last_value" table_alias="s"/>
        <field name="unit" table_alias="s"/>
        <field name="last_value_on" table_alias="s"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10002,'SELECTVIEW','default',10001,'id',10000,'<restapi type="select">
    <table name="iot_sensor" alias="s"/>
    <orderby>
        <field name="description" alias="s" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="s" alias="id"/>
        <field name="description" table_alias="s" alias="name"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10003,'LISTVIEW','default',10002,'id',10000,'<restapi type="select">
    <table name="iot_sensor_routing" alias="r"/>
    <filter type="or">
        <condition field="description" alias="r" value="$$query$$" operator=" like "/>
        <condition field="external_sensor_id" alias="r" value="$$query$$" operator=" like "/>
        <condition field="internal_sensor_id" alias="r" value="$$query$$" operator=" like "/>
    </filter>
    <joins>
        <join type="inner" table="iot_sensor_routing_status" alias="rs" condition="r.status_id=rs.id"/>
        <join type="left" table="iot_sensor" alias="s" condition="r.internal_sensor_id=s.id"/>
    </joins>
    <orderby>
        <field name="external_sensor_id" alias="r" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="r" alias="id"/>
        <field name="external_sensor_id" table_alias="r"/>
        <field name="internal_sensor_id" table_alias="r"/>
        <field name="description" table_alias="r" alias="Routing"/>
        <field name="description" table_alias="s" alias="Sensor"/>
        <field name="name" table_alias="rs" alias="status"/>
        <field name="last_value_on" table_alias="r"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10005,'LISTVIEW','default',10003,'id',10000,'<restapi type="select">
    <table name="iot_sensor_routing_status" alias="rs"/>
    <filter type="or">
        <condition field="name" alias="rs" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="id" alias="rs" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="rs" alias="id"/>
        <field name="name" table_alias="rs"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10006,'SELECTVIEW','default',10003,'id',10000,'<restapi type="select">
    <table name="iot_sensor_routing_status" alias="rs"/>
    <filter type="or">
        <condition field="name" alias="rs" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="id" alias="rs" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="rs" alias="id"/>
        <field name="name" table_alias="rs" alias="name"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10007,'LISTVIEW','default',10004,'id',10000,'<restapi type="select">
    <table name="iot_log_source" alias="l"/>
    <filter type="or">
        <condition field="name" alias="l" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="l" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="l" alias="id"/>
        <field name="name" table_alias="l"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10008,'SELECTVIEW','default',10004,'id',10000,'<restapi type="select">
    <table name="iot_log_source" alias="l"/>
    <filter type="or">
        <condition field="name" alias="l" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="l" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="l" alias="id"/>
        <field name="name" table_alias="l" alias="name"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10009,'LISTVIEW','default',10005,'id',10000,'<restapi type="select">
    <table name="iot_log" alias="l"/>
    <filter type="or">
        <condition field="name" alias="l" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="id" alias="l" sort="DESC"/>
    </orderby>
    <select>
        <field name="id" table_alias="l" alias="id"/>
        <field name="name" table_alias="l"/>
        <field name="message" table_alias="l"/>
        <field name="created_on" table_alias="l"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10011,'LISTVIEW','default',10006,'id',10000,'<restapi type="select">
    <table name="iot_node" alias="n"/>
    <filter type="or">
        <condition field="name" alias="n" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="n" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="n" alias="id"/>
        <field name="name" table_alias="n"/>
        <field name="ip_address" table_alias="n"/>
        <field name="last_heard_on" table_alias="n"/>
        <field name="last_error_code" table_alias="n"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10011,'SELECTVIEW','default',10006,'id',10000,'<restapi type="select">
    <table name="iot_node" alias="n"/>
    <orderby>
        <field name="name" alias="n" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="n" alias="id"/>
        <field name="name" table_alias="n"/>
    </select>
</restapi>');