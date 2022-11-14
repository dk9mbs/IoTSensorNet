DROP TABLE IF EXISTS iot_manual_sensor_data;

DELETE FROM api_process_log WHERE event_handler_id IN (SELECT id FROM api_event_handler WHERE solution_id=10000);

DELETE FROM api_ui_app_nav_item WHERE solution_id=10000;
DELETE FROM api_ui_app WHERE solution_id=10000;
DELETE FROM api_table_view WHERE solution_id=10000;
DELETE FROM api_event_handler WHERE solution_id=10000;

INSERT IGNORE INTO api_solution(id,name) VALUES (10000, 'IoTSensorNet');

CREATE TABLE IF NOT EXISTS iot_location(
    id int NOT NULL AUTO_INCREMENT,
    name varchar(50) NOT NULL,
    local_gateway_url nvarchar(500) NULL COMMENT 'URL for iot Gateway',
    PRIMARY KEY(id),
    UNIQUE KEY(name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE iot_location ADD COLUMN IF NOT EXISTS local_gateway_url nvarchar(500) NULL COMMENT 'URL for iot Gateway';

INSERT IGNORE INTO iot_location (id,name) VALUES (1,'DEFAULT');


/* Aktoren */
DROP TABLE IF EXISTS iot_device_attribute;
DROP TABLE IF EXISTS iot_device_routing;
DROP TABLE IF EXISTS iot_device;
DROP TABLE IF EXISTS iot_device_categorie_class_mapping;
DROP TABLE IF EXISTS iot_device_class;
DROP TABLE IF EXISTS iot_device_vendor;
DROP TABLE IF EXISTS iot_device_status;

CREATE TABLE IF NOT EXISTS iot_device_vendor(
    id nvarchar(50) NOT NULL,
    name nvarchar(50) NOT NULL,
    PRIMARY KEY(id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_device_vendor(id, name) VALUES ('tuya','Tuya');

CREATE TABLE IF NOT EXISTS iot_device_class(
    id nvarchar(50) NOT NULL,
    name nvarchar(50) NOT NULL,
    PRIMARY KEY(id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO iot_device_class(id, name) VALUES ('Bulb','Bulb');
INSERT INTO iot_device_class(id, name) VALUES ('Outlet','Wall outlet');

CREATE TABLE IF NOT EXISTS iot_device_status (
    id varchar(50) NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_device_status(id,name) VALUES ('new','New');
INSERT IGNORE INTO iot_device_status(id,name) VALUES ('active','Active');
INSERT IGNORE INTO iot_device_status(id,name) VALUES ('disabled','Disabled');

CREATE TABLE IF NOT EXISTS iot_device(
    id varchar(250) NOT NULL,
    name varchar(250) NOT NULL,
    product_id nvarchar(250) NULL,
    product_name nvarchar(250) NULL,
    address nvarchar(50) NOT NULL,
    local_key nvarchar(100) NULL,
    version nvarchar(50) NOT NULL DEFAULT '0',
    class_id varchar(50) NULL,
    category varchar(50) NULL,
    vendor_id nvarchar(50) NOT NULL,
    status_id nvarchar(50) NOT NULL DEFAULT 'new',
    location_id int NOT NULL DEFAULT '1',
    icon nvarchar(250) NULL,
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    last_scan_on timestamp NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(status_id) REFERENCES iot_device_status(id),
    FOREIGN KEY(class_id) REFERENCES iot_device_class(id),
    FOREIGN KEY(vendor_id) REFERENCES iot_device_vendor(id),
    FOREIGN KEY(location_id) REFERENCES iot_location(id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS iot_device_categorie_class_mapping(
    id int NOT NULL AUTO_INCREMENT COMMENT '',
    category nvarchar(50) NOT NULL,
    class_id nvarchar(50) NOT NULL COMMENT '',
    vendor_id nvarchar(50) NOT NULL COMMENT '',
    PRIMARY KEY(id),
    UNIQUE KEY(category, class_id, vendor_id),
    FOREIGN KEY(class_id) REFERENCES iot_device_class(id),
    FOREIGN KEY(vendor_id) REFERENCES iot_device_vendor(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE iot_device_categorie_class_mapping (category, class_id, vendor_id) VALUES ('cz','Outlet','tuya');
INSERT IGNORE iot_device_categorie_class_mapping (category, class_id, vendor_id) VALUES ('dj','Bulb','tuya');

CREATE TABLE IF NOT EXISTS iot_device_routing(
    id int NOT NULL AUTO_INCREMENT COMMENT '',
    internal_device_id nvarchar(250) NOT NULL COMMENT '',
    external_device_id nvarchar(250) NOT NULL COMMENT '',
    description varchar(50) NULL COMMENT 'description for this assignment',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY(external_device_id) REFERENCES iot_device(id),
    PRIMARY KEY(id),
    UNIQUE KEY(internal_device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS iot_device_attribute(
    id int NOT NULL AUTO_INCREMENT COMMENT 'Unique key',
    name nvarchar(100) NOT NULL COMMENT 'Name of the inter status',
    vendor_id nvarchar(50) NOT NULL COMMENT 'Vendor',
    class_id nvarchar(50) NULL COMMENT 'Device Class',
    device_attribute_key nvarchar(250) NOT NULL COMMENT 'The Attribute from the device',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL COMMENT 'Created on',
    PRIMARY KEY(id),
    UNIQUE KEY(name, vendor_id, class_id),
    FOREIGN KEY(class_id) REFERENCES iot_device_class(id),
    FOREIGN KEY(vendor_id) REFERENCES iot_device_vendor(id) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_device_attribute (name, vendor_id,class_id, device_attribute_key) VALUES ('power','tuya','Bulb','20');
INSERT IGNORE INTO iot_device_attribute (name, vendor_id,class_id, device_attribute_key) VALUES ('power','tuya','Outlet','1');


/* Ende Aktoren */

CREATE TABLE IF NOT EXISTS iot_node_status(
    id int NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_node_status(id, name) VALUES (10,'Active');
INSERT IGNORE INTO iot_node_status(id, name) VALUES (20,'Disabled');

CREATE TABLE IF NOT EXISTS iot_node (
    id int NOT NULL AUTO_INCREMENT,
    name varchar(250) NOT NULL,
    last_error_code int NULL,
    ip_address varchar(50) NULL,
    last_heard_on timestamp NULL,
    status_id int NOT NULL DEFAULT '0',
    PRIMARY KEY(id),
    FOREIGN KEY(status_id) REFERENCES iot_node_status(id),
    UNIQUE KEY(name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS location_id int NULL;
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS display_template text NULL;
ALTER TABLE iot_node ADD CONSTRAINT  FOREIGN KEY IF NOT EXISTS (location_id) REFERENCES iot_location (id);

CREATE TABLE IF NOT EXISTS iot_sensor_data(
    id int NOT NULL AUTO_INCREMENT,
    sensor_id varchar(250) NOT NULL,
    sensor_namespace varchar(500) NOT NULL,
    sensor_value numeric(15,4) NOT NULL,
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE iot_sensor_data ADD INDEX IF NOT EXISTS sensor_id_created_on (sensor_id, created_on);


CREATE TABLE IF NOT EXISTS iot_sensor_type(
    id int NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (1, 'DS 1820');
INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (2, 'DHT 11');
INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (3, 'DHT 22');

CREATE TABLE IF NOT EXISTS iot_sensor (
    id varchar(250) NOT NULL COMMENT 'unique id',
    alias varchar(250) NOT NULL COMMENT 'sensor_id',
    description varchar(250) NOT NULL,
    last_value decimal(15,4) DEFAULT NULL,
    last_value_on datetime DEFAULT NULL,
    min_value decimal(15,4) NOT NULL DEFAULT 0.0000,
    max_value decimal(15,4) NOT NULL DEFAULT 0.0000,
    unit varchar(50) NOT NULL default 'unit',
    days_in_history int NOT NULL default '0' COMMENT 'auto delete in days',
    auto_delete_sensor_data smallint NOT NULL default '0' COMMENT '0=yes -1=no',
    watchdog_warning_sec int(11) DEFAULT NULL COMMENT 'Watchdog warnmeldungen wenn x sec. keine Nachricht',
    type_id int(11) DEFAULT NULL,
    PRIMARY KEY(id),
  FOREIGN KEY (type_id) REFERENCES iot_sensor_type (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



ALTER TABLE iot_sensor ADD COLUMN IF NOT EXISTS type_id int NULL;
ALTER TABLE iot_sensor ADD CONSTRAINT  FOREIGN KEY IF NOT EXISTS (type_id) REFERENCES iot_sensor_type (id);


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


CREATE TABLE IF NOT EXISTS iot_manual_sensor_data_status (
    id int NOT NULL,
    name varchar(50) NOT NULL,
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_manual_sensor_data_status (id,name) VALUES (10,'New');
INSERT IGNORE INTO iot_manual_sensor_data_status (id,name) VALUES (20,'Processed');
INSERT IGNORE INTO iot_manual_sensor_data_status (id,name) VALUES (30,'Error');

CREATE TABLE IF NOT EXISTS iot_manual_sensor_data (
    id int NOT NULL AUTO_INCREMENT,
    name varchar(50) NOT NULL,
    external_sensor_id varchar(250) NOT NULL COMMENT 'External Sensor ID from iot_sensor_routing',
    value decimal(15,4) DEFAULT NULL,
    status_id int NOT NULL DEFAULT 10,
    error_text text NULL COMMENT 'In case of process error',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(status_id) REFERENCES iot_manual_sensor_data_status(id)
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

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10007,'iot_node_status','iot_node_status','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10008,'iot_location','iot_location','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10009,'iot_sensor_type','iot_sensor_type','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10010,'iot_manual_sensor_data','iot_manual_sensor_data','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10011,'iot_manual_sensor_data_status','iot_manual_sensor_data_status','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10012,'iot_device','iot_device','id','string','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10013,'iot_device_class','iot_device_class','id','string','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10014,'iot_device_vendor','iot_device_vendor','id','string','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10015,'iot_device_status','iot_device_status','id','string','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10016,'iot_device_categorie_class_mapping','iot_device_categorie_class_mapping','id','int','category',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10017,'iot_device_routing','iot_device_routing','id','int','description',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10018,'iot_device_attribute','iot_device_attribute','id','int','name',10000);

INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10017, 'ID','id','int','{"disabled": true}');
INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10017, 'Erstellt am','created_on','datetime','{"disabled": true}');
INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10018, 'ID','id','int','{"disabled": true}');
INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10018, 'Erstellt am','created_on','datetime','{"disabled": true}');


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
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10007,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10008,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10009,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10010,-1,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10011,0,-1,0,10000);

INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10012,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10013,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10014,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10015,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10016,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10017,0,-1,0,10000);



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
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10007,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10008,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10009,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10010,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10011,-1,-1,-1,-1,10000);

INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10012,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10013,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10014,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10015,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10016,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10017,-1,-1,-1,-1,10000);



INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES ('iot_sensor_routing','iot_sensor_data','insert','before',90,10000);

INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES ('iot_setlast_value','iot_sensor_data','insert','before',100,10000);

INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES ('iot_set_node_status','iot_log','insert','before',100,10000);

INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES ('iot_action_display','iot_get_node_display_text','execute','before',100,10000);

INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES ('iot_app_start','$app_start','execute','before',100,10000);

INSERT IGNORE INTO api_event_handler (plugin_module_name,publisher,event,type,sorting,run_async,solution_id) 
    VALUES ('iot_pl_man_sensor_data','iot_manual_sensor_data','insert','after',100,-1,10000);



INSERT IGNORE INTO api_ui_app (id, name,description,home_url,solution_id) 
VALUES (
10000,'IoT Service App','System Verwaltungs App','/ui/v1.0/data/view/iot_sensor/default?app_id=10000',10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10000,10000,'Sensoren','/ui/v1.0/data/view/iot_sensor/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10001,10000,'Sensor Daten (avg)','/ui/v1.0/data/view/iot_sensor_data/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10002,10000,'Nodes','/ui/v1.0/data/view/iot_node/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10003,10000,'Logs','/ui/v1.0/data/view/iot_log/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10004,10000,'Routing','/ui/v1.0/data/view/iot_sensor_routing/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10005,10000,'Locations','/ui/v1.0/data/view/iot_location/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10006,10000,'Sensor Typen','/ui/v1.0/data/view/iot_sensor_type/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10007,10000,'Zählerstandserfassung','/ui/v1.0/data/view/iot_manual_sensor_data/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10008,10000,'Status werte Zählerstandserfassung','/ui/v1.0/data/view/iot_manual_sensor_data_status/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10009,10000,'Aktoren','/ui/v1.0/data/view/iot_device/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10010,10000,'Kategorien Mapping','/ui/v1.0/data/view/iot_device_categorie_class_mapping/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10011,10000,'Device Routing','/ui/v1.0/data/view/iot_device_routing/default',1,10000);





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
    <joins>
        <join type="left" table="iot_sensor_type" alias="st" condition="s.type_id=st.id"/>
    </joins>
    <select>
        <field name="id" table_alias="s" alias="id" header="ID"/>
        <field name="name" table_alias="st" header="Type"/>
        <field name="description" table_alias="s" header="Description"/>
        <field name="last_value" table_alias="s" header="Value (current)"/>
        <field name="unit" table_alias="s" header="Unit"/>
        <field name="last_value_on" table_alias="s" header="Last value on"/>
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
        <field name="node_id" table_alias="l"/>
        <field name="node_name" table_alias="l"/>
        <field name="ip_address" table_alias="l"/>
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
    <joins>
        <join type="inner" table="iot_node_status" alias="ns" condition="n.status_id=ns.id"/>
        <join type="left" table="iot_location" alias="l" condition="n.location_id=l.id"/>
    </joins>
    <select>
        <field name="id" table_alias="n" alias="id" header="ID"/>
        <field name="name" table_alias="n" alias="test" header="Node Name"/>
        <field name="ip_address" table_alias="n" header="IP"/>
        <field name="last_heard_on" table_alias="n" header="Last heard"/>
        <field name="last_error_code" table_alias="n" header="Last Error"/>
        <field name="name" table_alias="ns" header="Status"/>
        <field name="name" table_alias="l" alias="location_name" header="Location"/>
        <field name="status_id" table_alias="n" header="StatusID"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10012,'SELECTVIEW','default',10006,'id',10000,'<restapi type="select">
    <table name="iot_node" alias="n"/>
    <orderby>
        <field name="name" alias="n" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="n" alias="id"/>
        <field name="name" table_alias="n"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10013,'LISTVIEW','default',10007,'id',10000,'<restapi type="select">
    <table name="iot_node_status" alias="n"/>
    <orderby>
        <field name="name" alias="n" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="n" alias="id"/>
        <field name="name" table_alias="n" alias="name"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10014,'SELECTVIEW','default',10007,'id',10000,'<restapi type="select">
    <table name="iot_node_status" alias="n"/>
    <orderby>
        <field name="name" alias="n" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="n" alias="id"/>
        <field name="name" table_alias="n" alias="name"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10015,'LISTVIEW','default',10008,'id',10000,'<restapi type="select">
    <table name="iot_location" alias="l"/>
    <filter type="or">
        <condition field="name" alias="l" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="l" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="l" alias="id" header="ID"/>
        <field name="name" table_alias="l" alias="test" header="Location"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10016,'SELECTVIEW','default',10008,'id',10000,'<restapi type="select">
    <table name="iot_location" alias="l"/>
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
10017,'LISTVIEW','default',10009,'id',10000,'<restapi type="select">
    <table name="iot_sensor_type" alias="t"/>
    <filter type="or">
        <condition field="name" alias="t" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="t" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="t" alias="id" header="ID"/>
        <field name="name" table_alias="t" alias="test" header="Name"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10018,'SELECTVIEW','default',10009,'id',10000,'<restapi type="select">
    <table name="iot_sensor_type" alias="t"/>
    <orderby>
        <field name="name" alias="t" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="t" alias="id"/>
        <field name="name" table_alias="t" alias="name"/>
    </select>
</restapi>');

/* avg over sensor */
INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10019,'LISTVIEW','default',10000,'id',10000,'<restapi type="select">
    <table name="iot_sensor_data" alias="sd"/>
    <filter type="and">
        <condition field="sensor_value" alias="sd" operator="notnull"/>
        <condition field="id" alias="s" operator="notnull"/>
        <filter type="and">
            <condition field="sensor_id" alias="sd" value="$$query$$" operator=" like "/>
        </filter>
    </filter>
    <joins>
        <join type="left" table="iot_sensor" alias="s" condition="sd.sensor_id=s.id"/>
    </joins>
    <select>
        <field name="id" table_alias="s" alias="id" grouping="y" header="ID"/>
        <field name="description" table_alias="s" grouping="y" header="Description"/>
        <field name="sensor_value" table_alias="sd" func="avg" alias="last_value" header="Value (avg)"/>
        <field name="unit" table_alias="s" grouping="y" header="Unit"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10020,'LISTVIEW','default',10010,'id',10000,'<restapi type="select">
    <table name="iot_manual_sensor_data" alias="m"/>
    <filter type="or">
        <condition field="name" alias="m" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <joins>
        <join type="inner" table="iot_manual_sensor_data_status" alias="s" condition="s.id=m.status_id"/>
    </joins>
    <orderby>
        <field name="created_on" alias="m" sort="DESC"/>
    </orderby>
    <select>
        <field name="id" table_alias="m" alias="id" header="ID"/>
        <field name="name" table_alias="m" header="Name"/>
        <field name="external_sensor_id" table_alias="m" header="Zähler"/>
        <field name="value" table_alias="m" header="Wert"/>
        <field name="name" alias="status_name" table_alias="s" header="Status"/>
        <field name="error_text" table_alias="m" header="Fehler"/>
        <field name="created_on" table_alias="m" header="Datum"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10021,'LISTVIEW','default',10012,'id',10000,'<restapi type="select">
    <table name="iot_device" alias="d"/>
    <filter type="or">
        <condition field="name" alias="d" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <joins>
        <join type="inner" table="iot_device_status" alias="s" condition="s.id=d.status_id"/>
    </joins>
    <orderby>
        <field name="created_on" alias="d" sort="DESC"/>
    </orderby>
    <select>
        <field name="id" table_alias="d" alias="id" header="ID"/>
        <field name="name" table_alias="d" header="Name"/>
        <field name="address" table_alias="d" header="Adresse"/>
        <field name="name" alias="status_name" table_alias="s" header="Status"/>
        <field name="class_id" table_alias="d" header="Geräte Klasse"/>
        <field name="last_scan_on" table_alias="d" header="Letzter Netzwerk Scan"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10022,'LISTVIEW','default',10016,'id',10000,'<restapi type="select">
    <table name="iot_device_categorie_class_mapping" alias="m"/>
    <filter type="or">
        <condition field="category" alias="m" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <orderby>
        <field name="category" alias="m" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="m" alias="id" header="ID"/>
        <field name="category" table_alias="m" header="Kategorie"/>
        <field name="class_id" table_alias="m" header="Klasse"/>
        <field name="vendor_id" table_alias="m" header="Hersteller"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10023,'LISTVIEW','default',10017,'id',10000,'<restapi type="select">
    <table name="iot_device_routing" alias="r"/>
    <filter type="or">
        <condition field="internal_device_id" alias="r" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <orderby>
        <field name="internal_device_id" alias="r" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="r" alias="id" header="ID"/>
        <field name="internal_device_id" table_alias="r" header="Intern"/>
        <field name="external_device_id" table_alias="r" header="Extern"/>
        <field name="description" table_alias="r" header="Bemerkung"/>
        <field name="created_on" table_alias="r" header="Erstellt am"/>
    </select>
</restapi>');





