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
