#!/bin/bash

set -ex

TSSUB=BanaRedmineG1
TSRG=TemplateSpecRG
TSNAME=RedminePlanMySQL
TSVER=0.0.1

cd $(dirname $0)

az ts create -y --subscription $TSSUB -g $TSRG -n $TSNAME -v $TSVER --template-file main.bicep
