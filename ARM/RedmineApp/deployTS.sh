#!/bin/bash

set -ex

TSSUB=1345aada-c7ce-4a7a-aa5f-35fa9a8ccb79
TSRG=TemplateSpecRG
TSNAME=RedmineApp
TSVER=0.0.1

cd $(dirname $0)

az ts create -y --subscription $TSSUB -g $TSRG -n $TSNAME -v $TSVER --template-file main.bicep --ui-form-definition uiform.json
