return {
    ["Felicya"] = {
        ['c'] = {
            ['enabled'] = false,
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
        ['boss'] = {
            ['enabled'] = false,
            ['actions'] = {
                {
                    ['player']='Happylaw',
                    ['ability']='アップヒーバル',
                    ['action']='トアクリーバー',
                },
                {
                    ['player']='Happylaw',
                    ['ability']='インパルスドライヴ',
                    ['action']='トアクリーバー',
                },
            },
        },
        ['cor'] = {
            ['enabled'] = false,
            ['actions'] = {
                {
                    ['player']='Frieren',
                    ['ability']='ラストスタンド',
                    ['action']='サベッジブレード',
                },
            },
        },
        ['gax'] = {
            ['enabled'] = false,
            ['chain'] = {'フルブレイク','アップヒーバル','ウッコフューリー','ウッコフューリー'},
            ['actions'] = {
                {
                    ['player']='Felicya',
                    ['ability']='フルブレイク',
                    ['action']='アップヒーバル',
                },
                {
                    ['player']='Felicya',
                    ['ability']='アップヒーバル',
                    ['action']='ウッコフューリー',
                },
                {
                    ['player']='Felicya',
                    ['ability']='ウッコフューリー',
                    ['action']='ウッコフューリー',
                },
            },
        },
    }
}
