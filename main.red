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
deleteHistoriesPath: "/delete-histories"
loginPath: "/login"

inco: context [

    token: ""

    histories: []

    selected-histories: []

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

    joinWith: function [
        strings [block!]
        delimiter [string!]
        return: [string!]
    ] [
        collect/into [
            foreach str strings [
                keep rejoin [str delimiter]
            ]
        ] output: copy ""
        remove back tail output
        return output
    ]

    delete-histories: function [
        ids [block!]
    ] [
        url: rejoin [baseUrl deleteHistoriesPath]
        request: [POST []]
        append last request compose [
            Authorization: (rejoin ["Bearer " token])
        ]
        append request rejoin ["id=" joinWith ids ","]
        print make string! write/lines make url! url request
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

selected-list: make face! [
    type: 'text-list
    offset: 400x0
    size: 400x450
    data: []
    actors: object [
        on-change: function [
            face [object!]
            event [event!]
        ][
            index: face/selected
            unless index == 0 [
                append/only inco/histories take at inco/selected-histories index
                append base-list/data take at face/data index
            ]
        ]
    ]
]

base-list: make face! [
    type: 'text-list
    size: 400x450
    data: []
    actors: object [
        on-create: function [face [object!]][
            histories: inco/get-histories face
            foreach history histories [
                decrypted: copy ""
                result: call/output rejoin ["./decrypt.sh " {"} select history 'url {"}] decrypted
                if result == 0 [
                    append/only inco/histories reduce [decrypted select history 'id]
                    append face/data decrypted
                ]
            ]
        ]
        on-change: function [
            face [object!]
            event [event!]
        ][
            index: face/selected
            unless index == 0 [
                append/only inco/selected-histories take at inco/histories index
                append selected-list/data take at face/data index
            ]
        ]
    ]
]

histories-view: make face! [
    type: 'window
    text: "Inco"
    size: 800x500
    pane: reduce [
        base-list
        selected-list
        make face! [
            type: 'button
            text: "Delete"
            size: 100x50
            offset: 700x450
            actors: object [
                on-click: function [
                    face [object!]
                    event [event!]
                ] [
                    ids: collect [foreach blk inco/selected-histories [keep blk/2]]
                    inco/delete-histories ids
                    clear inco/selected-histories
                    clear selected-list/data
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
