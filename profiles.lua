return {
    ["Felicya"] = {
        ['c'] = {
            ['enabled'] = false,
            ['toss'] = "レッドロータス",
            ['actions'] = {
                {
                    ['player']='Felicya',
                    ['ability']='レッドロータス',
                    ['action']='フラットブレード',
                },
                -- {
                    -- ['player']='Felicya',
                    -- ['ability']='フラットブレード',
                    -- ['action']='サベッジブレード',
                -- },
            },
        },
        ['d'] = {
            ['enabled'] = false,
            ['actions'] = {
                {
                    ['player']='Felicya',
                    ['ability']='レッドロータス',
                    ['action']='ファストブレード',
                },
                {
                    ['player']='Felicya',
                    ['ability']='ファストブレード',
                    ['action']='レッドロータス',
                },
            },
        },
        ['gax'] = {
            ['enabled'] = false,
            ['chain'] = {'フルブレイク','アップヒーバル','ウッコフューリー','ウッコフューリー','アップヒーバル','ウッコフューリー','アップヒーバル','ウッコフューリー'},
        },
        ['gax2'] = {
            ['enabled'] = false,
            ['chain'] = {'ウッコフューリー','アップヒーバル'},
        },
        ['ef'] = {
            ['enabled'] = false,
            ['actions'] = {
                {
                    ['player']='Foka',
                    ['ability']='アップヒーバル',
                    -- ['action']='サベッジブレード',
                    ['action']='シャークバイト',
                },
            },
        },
    }
}
