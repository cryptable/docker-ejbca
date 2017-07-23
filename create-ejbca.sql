
CREATE DATABASE ejbca CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER 'ejbca'@'localhost' IDENTIFIED BY 'ejbca';
GRANT ALL PRIVILEGES ON ejbca.* TO 'ejbca'@'localhost' IDENTIFIED BY 'ejbca';