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

DELETE FROM api_group_permission WHERE group_id IN(10000,10001);
DELETE FROM api_user_group WHERE user_id IN(10000,10001);
DELETE FROM api_table WHERE id IN (10000,10001);
DELETE FROM api_user WHERE id IN(10000,10001);
DELETE FROM api_group WHERE id IN (10000,10001);

INSERT INTO api_user (id,username,password,is_admin,disabled) VALUES (10000,'IoTSrv','password',0,-1);
INSERT INTO api_user (id,username,password,is_admin,disabled) VALUES (10001,'IoTAdmin','password',0,-1);

INSERT INTO api_group(id,groupname) VALUES (10000,'IoTSensorNetworkSrv');
INSERT INTO api_group(id,groupname) VALUES (10001,'IoTSensorNetworkAdmin');

INSERT INTO api_user_group(user_id,group_id) VALUES (10000,10000);
INSERT INTO api_user_group(user_id,group_id) VALUES (10001,10001);


INSERT INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name) 
    VALUES
    (10000,'iot_sensor_data','iot_sensor_data','id','Int','sensor_value');

INSERT INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name) 
    VALUES
    (10001,'iot_sensor','iot_sensor','id','Int','description');


INSERT INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update)
    VALUES
    (10000,10000,-1,-1,0);
INSERT INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update)
    VALUES
    (10000,10001,0,-1,0);

/* Admin */
INSERT INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete)
    VALUES
    (10001,10000,-1,-1,-1,-1);
INSERT INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete)
    VALUES
    (10001,10001,-1,-1,-1,-1);

