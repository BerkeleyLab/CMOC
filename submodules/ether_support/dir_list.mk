TOP := $(dir $(lastword $(MAKEFILE_LIST)))
SUBMODULES_DIR := $(TOP)submodules/
BUILD_DIR = $(SUBMODULES_DIR)build
COMMON_HDL_DIR = $(SUBMODULES_DIR)common-hdl
CORE_DIR = $(TOP)core
CLIENTS_DIR = $(TOP)clients
CRC_DIR = $(TOP)crc
MODEL_DIR = $(TOP)model
