#!/bin/bash
FILENAME=/usr/local/lib/python3.6/site-packages/butterfly/static/main.css

cat << EOF >> $FILENAME

@supports (-webkit-overflow-scrolling: touch) {
    html, body {
        height: 100%;
        overflow: auto;
        overflow-x: hidden;
        -webkit-overflow-scrolling: touch;
    }
}}
EOF
