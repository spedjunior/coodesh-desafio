#!/bin/bash

# Variáveis de ambiente
DIR_LOCAL="./site"
BUCKET_NAME="$1"

# Upload do diretório local para o bucket S3
aws s3 cp $DIR_LOCAL s3://$BUCKET_NAME --recursive