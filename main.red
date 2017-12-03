; Copyright 2017 Yoshihiro Tanaka
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;
; Author: Yoshihiro Tanaka <contact@cordea.jp>
; date  : 2017-12-03

Red [
    Title: "Inco manager"
    ; red-tools https://github.com/rebolek/red-tools
    Needs: 'View
]

#include %red-tools/json.red

baseUrl: "http://localhost:8080"
historiesPath: "/histories"
loginPath: "/login"

inco: context [

    token: ""

    get-histories: function [
        return: [block!]
    ] [
        url: rejoin [baseUrl historiesPath]
        request: [GET []]
        append last request compose [
            Authorization: (rejoin ["Bearer " token])
        ]
        append request ""
        response: write/lines make url! url request
        decoded: json/decode make string! response
        return decoded
    ]

    login: function [
        f [object!]
        return: [string!]
    ] [
        root: f/parent
        info: collect [foreach-face/with root [keep face/text] [face/type == 'field]]
        url: rejoin [baseUrl loginPath "?user=" first info "&pass=" next info]
        decoded: json/decode make string! write/lines make url! url []
        return select decoded 'token
    ]

    init: function [

    ] [

    ]
]

histories-view: make face! [
    type: 'window text: "Inco" size: 800x500
    pane: reduce [
        make face! [
            type: 'text-list size: 800x500
            data: []
            actors: object [
                on-create: function [face [object!]][
                    histories: inco/get-histories face
                    foreach history histories [
                        print select history 'url
                    ]
                ]
            ]
        ]
    ]
]

inco/init

view [
    style txt: text right 45
    group-box [
        txt "Username" field return
        txt "Password" field
    ] return
    button: button "Submit" [
        token: inco/login button
        if token [
            inco/token: token
            view histories-view
        ]
    ]
]
