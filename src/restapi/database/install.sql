DELETE FROM api_table_view WHERE solution_id=10000;

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

INSERT IGNORE INTO api_solution(id,name) VALUES (10000, 'IoTSensorNet');

INSERT IGNORE INTO api_user (id,username,password,is_admin,disabled,solution_id) VALUES (10000,'IoTSrv','password',0,0,10000);
INSERT IGNORE INTO api_user (id,username,password,is_admin,disabled,solution_id) VALUES (10001,'IoTAdmin','password',0,-1,10000);

INSERT IGNORE INTO api_group(id,groupname,solution_id) VALUES (10000,'IoTSensorNetworkSrv',10000);
INSERT IGNORE INTO api_group(id,groupname,solution_id) VALUES (10001,'IoTSensorNetworkAdmin',10000);

INSERT IGNORE INTO api_user_group(user_id,group_id,solution_id) VALUES (10000,10000,10000);
INSERT IGNORE INTO api_user_group(user_id,group_id,solution_id) VALUES (10001,10001,10000);


INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10000,'iot_sensor_data','iot_sensor_data','id','Int','sensor_value',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id) 
    VALUES
    (10001,'iot_sensor','iot_sensor','id','Int','description',10000);


INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10000,-1,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10001,0,-1,0,10000);

/* Admin */
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10000,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10001,-1,-1,-1,-1,10000);

INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES ('iot_setlast_value','iot_sensor_data','insert','before',100,10000);

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

