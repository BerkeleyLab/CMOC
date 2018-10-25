TOP := $(dir $(lastword $(MAKEFILE_LIST)))
SUBMODULES := $(TOP)submodules/
BUILD_DIR = $(SUBMODULES)build

APP_DIR = $(TOP)sel4v
RTSIM_DIR = $(SUBMODULES)rtsim
COMMON_HDL_DIR = $(SUBMODULES)common_hdl
PERIPHERAL_DRIVERS_DIR = $(SUBMODULES)peripheral_drivers
FPGA_FAMILY_DIR = $(SUBMODULES)fpga_family

ETHER_SUPPORT_DIR = $(SUBMODULES)ether_support
ETHER_CORE_DIR = $(ETHER_SUPPORT_DIR)/core
ETHER_CLIENTS_DIR = $(ETHER_SUPPORT_DIR)/clients
ETHER_CRC_DIR = $(ETHER_SUPPORT_DIR)/crc
ETHER_TOP_DIR = $(ETHER_SUPPORT_DIR)/common_top

BOARD_SUPPORT_DIR = $(SUBMODULES)board_support
BS_HARDWARE_DIR = $(BOARD_SUPPORT_DIR)/$(HARDWARE)
FMC_DAUGHTER_DIR = $(BOARD_SUPPORT_DIR)/$(DAUGHTER)

DEPDIR = _dep
AUTOGEN_DIR = _autogen
