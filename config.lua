Config   = {}

Config.Locale = 'en'
Config.lastname = true

Locales = {}

function LoadLocales(language)
    local file = ("locales/%s.lua"):format(language)
    local content = LoadResourceFile(GetCurrentResourceName(), file)
    
    if content then
        local chunk, err = load(content, ('@@%s'):format(file))
        if chunk then
            local ok, result = pcall(chunk)
            if ok then
                Locales = result or {}
                return Locales
            else
                print(("^1Error loading locales (%s): %s^7"):format(file, result))
            end
        else
            print(("^1Error parsing locales (%s): %s^7"):format(file, err))
        end
    end
    
    if language ~= "en" then
        print(("^3Locale %s not found, falling back to english^7"):format(language))
        return LoadLocales("en")
    end
    
    return {}
end

function _(key, ...)
    local directTranslation = Locales[key]
    if directTranslation ~= nil then
        if type(directTranslation) == "string" and select('#', ...) > 0 then
            return directTranslation:format(...)
        end
        return directTranslation
    end
    
    local keys = {}
    for k in key:gmatch("[^.]+") do
        table.insert(keys, k)
    end
    
    local translation = Locales
    for _, k in ipairs(keys) do
        translation = translation and translation[k]
    end
    
    translation = translation or key
    
    if type(translation) == "string" and select('#', ...) > 0 then
        return translation:format(...)
    end
    return translation
end

Locales = LoadLocales(Config.Locale)