-- -------------
-- Version 2.04 updates:
-- Changes to support territory persistence, capture logging and donator levels
-- ------------

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema a3wasteland
-- -----------------------------------------------------
USE `a3wasteland` ;


-- -----------------------------------------------------
-- Update Table `playerinfo` to add DonatorLevel field
-- -----------------------------------------------------
ALTER TABLE `playerinfo` 
  ADD `DonatorLevel` INT NULL DEFAULT '0' AFTER BankMoney;

-- -----------------------------------------------------
-- Table `territorycapturestatus`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `territorycapturestatus` (
  `ID` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `ServerID` INT(10) UNSIGNED NOT NULL,
  `MapID` INT(10) UNSIGNED NOT NULL,
  `MarkerName` VARCHAR(45) NOT NULL DEFAULT '""',
  `Occupiers` VARCHAR(2048) NULL DEFAULT NULL,
  `SideHolder` VARCHAR(45) NULL DEFAULT '"UNKNOWN"',
  `GroupHolder` VARCHAR(128) NULL DEFAULT NULL,
  `GroupHolderUIDs` VARCHAR(2048) NULL DEFAULT NULL,
  `TimeHeld` FLOAT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  INDEX `fk_TerritoryCaptureStatus_ServerMap1_idx` (`MapID` ASC),
  INDEX `fk_TerritoryCaptureStatus_ServerInstance1_idx` (`ServerID` ASC),
  CONSTRAINT `fk_TerritoryCaptureStatus_ServerInstance1`
    FOREIGN KEY (`ServerID`)
    REFERENCES `serverinstance` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_TerritoryCaptureStatus_ServerMap1`
    FOREIGN KEY (`MapID`)
    REFERENCES `servermap` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `territorycapturelog`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `territorycapturelog` (
  `ID` INT(10) UNSIGNED NOT NULL,
  `MarkerName` VARCHAR(45) NOT NULL DEFAULT '""',
  `Occupiers` VARCHAR(2048) NULL,
  `CaptureTime` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `SideHolder` VARCHAR(45) NOT NULL DEFAULT '""',
  `GroupHolder` VARCHAR(128) NULL DEFAULT NULL,
  INDEX `fk_territorycapturelog_territorycapturestatus1_idx` (`ID` ASC),
  INDEX `ID_captureTime_idx` (`ID` ASC, `CaptureTime` ASC),
  CONSTRAINT `fk_territorycapturelog_territorycapturestatus1`
    FOREIGN KEY (`ID`)
    REFERENCES `territorycapturestatus` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


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