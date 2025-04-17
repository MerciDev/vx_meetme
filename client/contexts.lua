local QBCore = exports['qb-core']:GetCoreObject()

lib.registerMenu({
    id = 'meetme_main',
    title = _('meetme_main.title'),
    position = 'bottom-right',
    options = {
        {
            label = _('meetme_main.option1.label'),
            description = _('meetme_main.option1.description'),
            icon = 'users',
        },
        {
            label = _('meetme_main.option2.label'),
            description = _('meetme_main.option2.description'),
            icon = 'sliders'
        },
    }
}, function(selected, scrollIndex, args)
    if selected == 1 then
        UpdatePeopleList()
        lib.showMenu('meetme_list')
    elseif selected == 2 then
        Editing = true
        LoadSettings()
        lib.showMenu('meetme_config_do')
    end
end)

lib.registerMenu({
    id = 'meetme_list',
    title = _('meetme_list.title'),
    position = 'bottom-right',
    options = {},
    onClose = function()
        lib.showMenu('meetme_main')
    end
}, function(selected, scrollIndex, args)
    if (args and args['id']) then
        lib.closeInputDialog()
        Citizen.Wait(500)
        local input = lib.inputDialog(_('meetme_list.delete_dialog', args['name']),
            {
                { type = 'input', label = _('meetme_list.input_label'), placeholder = _('meetme_list.input_placeholder'), default = '' }
            })
        if input then
            if input[1] == _('meetme_list.input_placeholder') then TriggerServerEvent('meetme:removeContact', args['id']) end
        end
    end
    lib.showMenu('meetme_main')
end)

lib.registerMenu({
    id = 'meetme_config_do',
    title = _('meetme_config_do.title'),
    position = 'bottom-right',
    options = {
        {
            label = _('meetme_config_do.option1.label'),
            description = _('meetme_config_do.option1.description'),
            icon = 'magnifying-glass'
        },
        {
            label = _('meetme_config_do.option2.label'),
            description = _('meetme_config_do.option2.description'),
            icon = 'comment'
        },
        {
            label = _('meetme_config_do.option3.label'),
            description = _('meetme_config_do.option3.description'),
            icon = 'ruler'
        },
        {
            label = _('meetme_config_do.option4.label'),
            description = _('meetme_config_do.option4.description'),
            icon = 'clock'
        },
        {
            label = _('meetme_config_do.option5.label'),
            description = _('meetme_config_do.option5.description'),
            icon = 'check'
        }
    },
    onClose = function()
        lib.showMenu('meetme_main')
    end
}, function(selected, scrollIndex, args)
    if selected == 1 then
        local input = lib.inputDialog(_('meetme_config_do.input_inspect_title'), {
            {
                type = 'input',
                label = _('meetme_config_do.input_inspect_label'),
                placeholder = _('meetme_config_do.input_inspect_placeholder'),
                default = Settings.inspectMessage
            }
        })
        if input then
            Settings.inspectMessage = input[1]
        end
        lib.showMenu('meetme_config_do')
    elseif selected == 2 then
        local input = lib.inputDialog(_('meetme_config_do.input_auto_title'), {
            {
                type = 'input',
                label = _('meetme_config_do.input_auto_label'),
                placeholder = _('meetme_config_do.input_auto_placeholder'),
                default = Settings.autoMessage
            }
        })
        if input then
            Settings.autoMessage = input[1]
        end
        lib.showMenu('meetme_config_do')
    elseif selected == 3 then
        local input = lib.inputDialog(_('meetme_config_do.input_range_title'), {
            {
                type = 'number',
                label = _('meetme_config_do.input_range_label'),
                min = 1,
                max = 50,
                step = 1,
                default = Settings.messageRange,
                required = true
            }
        })
        if input then
            Settings.messageRange = input[1]
        end
        lib.showMenu('meetme_config_do')
    elseif selected == 4 then
        local input = lib.inputDialog(_('meetme_config_do.input_cooldown_title'), {
            {
                type = 'number',
                label = _('meetme_config_do.input_cooldown_label'),
                min = 1,
                max = 60,
                default = Settings.messageCooldown,
                required = true
            }
        })
        if input then
            Settings.messageCooldown = input[1]
        end
        lib.showMenu('meetme_config_do')
    elseif selected == 5 then
        Editing = false
        TriggerServerEvent('meetme:saveSettings', Settings)
        lib.showMenu('meetme_config_do')
    end
end)
