-- -------------
-- Version 2.04 updates:
-- Change to support territory persistence and capture logging
-- ------------

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Table `TerritoryCaptureStatus`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TerritoryCaptureStatus` (
  `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ServerID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL,
  `MarkerName` VARCHAR(45) NOT NULL DEFAULT '\"\"',
  `Occupiers` VARCHAR(45) NULL,
  `SideHolder` VARCHAR(45) NULL DEFAULT '\"UNKNOWN\"',
  `TimeHeld` FLOAT NULL DEFAULT 0,
  PRIMARY KEY (`ID`),
  INDEX `fk_TerritoryCaptureStatus_ServerMap1_idx` (`MapID` ASC),
  INDEX `fk_TerritoryCaptureStatus_ServerInstance1_idx` (`ServerID` ASC),
  CONSTRAINT `fk_TerritoryCaptureStatus_ServerMap1`
    FOREIGN KEY (`MapID`)
    REFERENCES `ServerMap` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_TerritoryCaptureStatus_ServerInstance1`
    FOREIGN KEY (`ServerID`)
    REFERENCES `ServerInstance` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TerritoryCaptureLog`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TerritoryCaptureLog` (
  `ServerID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL,
  `MarkerName` VARCHAR(45) NOT NULL DEFAULT '\"\"',
  `CaptureTime` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `SideHolder` VARCHAR(45) NOT NULL DEFAULT '\"\"',
  INDEX `fk_TerritoryCaptureLog_ServerInstance1_idx` (`ServerID` ASC),
  INDEX `fk_TerritoryCaptureLog_ServerMap1_idx` (`MapID` ASC),
  CONSTRAINT `fk_TerritoryCaptureLog_ServerInstance1`
    FOREIGN KEY (`ServerID`)
    REFERENCES `ServerInstance` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_TerritoryCaptureLog_ServerMap1`
    FOREIGN KEY (`MapID`)
    REFERENCES `ServerMap` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- -----------------------------------------------------
-- Data for table `DBInfo`
-- -----------------------------------------------------
START TRANSACTION;
USE `a3wasteland`;
UPDATE `DBInfo` set  Value='2.04' WHERE Name='Version';

COMMIT;