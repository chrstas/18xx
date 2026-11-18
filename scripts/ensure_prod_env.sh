#!/bin/bash

bad_vars_msg=""

if [ -z "${DATABASE_URL}" ]; then
    bad_vars_msg="${bad_vars_msg}\n- DATABASE_URL"
fi

if [ -z "${ELASTIC_KEY}" ]; then
    bad_vars_msg="${bad_vars_msg}\n- ELASTIC_KEY"
fi

if [ -z "${POSTGRES_USER}" ]; then
    bad_vars_msg="${bad_vars_msg}\n- POSTGRES_USER"
fi

if [ -z "${POSTGRES_PASSWORD}" ]; then
    bad_vars_msg="${bad_vars_msg}\n- POSTGRES_PASSWORD"
fi

if [ -z "${POSTGRES_DB}" ]; then
    bad_vars_msg="${bad_vars_msg}\n- POSTGRES_DB"
fi

if [ -z "${TURNSTILE_SECRET}" ]; then
    bad_vars_msg="${bad_vars_msg}\n- TURNSTILE_SECRET"
fi

if [ -z "${TURNSTILE_SITEKEY}" ]; then
    bad_vars_msg="${bad_vars_msg}\n- TURNSTILE_SITEKEY"
fi

if [ -z "${TURNSTILE_HOSTS}" ]; then
    bad_vars_msg="${bad_vars_msg}\n- TURNSTILE_HOSTS"
fi

if [ -z "${MAIL_FROM}" ]; then
    bad_vars_msg="${bad_vars_msg}\n- MAIL_FROM"
fi

if [ ! -z "${bad_vars_msg}" ]; then
    echo "ERROR: no values found for the following environment variables:"
    echo -e "${bad_vars_msg}"
    exit 1
fi
