local M = {}

-- Конфигурация
local config = {
  default_device = nil, -- Имя устройства по умолчанию
  devices = {}, -- Список устройств { name = "device1", ip = "192.168.1.100" }
  config_file = vim.fn.stdpath("config") .. "/webos_config.json",
}

-- Получить список устройств из ares
local function get_ares_devices(callback)
  vim.fn.jobstart({ "ares-device-info", "-l" }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      local devices = {}
      if data then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            -- Парсим вывод ares-device-info -l
            -- Форматы могут быть разными:
            -- "device_name"
            -- "device_name (192.168.1.100)"
            -- "device_name - 192.168.1.100"
            -- "device_name\t192.168.1.100"
            line = line:gsub("^%s+", ""):gsub("%s+$", "") -- Убираем пробелы в начале и конце
            if line ~= "" then
              local name = line:match("^([^%s%(%-]+)")
              local ip = line:match("%(([%d%.]+)%)") 
                     or line:match("%- (%d+%.%d+%.%d+%.%d+)")
                     or line:match("\t(%d+%.%d+%.%d+%.%d+)")
                     or line:match(" (%d+%.%d+%.%d+%.%d+)$")
              
              if name then
                -- Убираем лишние символы из имени
                name = name:gsub("^%s+", ""):gsub("%s+$", "")
                table.insert(devices, {
                  name = name,
                  ip = ip or "",
                })
              end
            end
          end
        end
      end
      if callback then
        callback(devices)
      end
    end,
    on_stderr = function(_, data)
      if data then
        local error_msg = table.concat(data, "\n")
        -- Игнорируем предупреждения, которые не критичны
        if not error_msg:match("No devices") and not error_msg:match("not found") then
          vim.notify("Ошибка получения списка устройств: " .. error_msg, vim.log.levels.ERROR)
        end
      end
      if callback then
        callback({})
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 and callback then
        -- Если код не 0, но устройств нет, это нормально
        callback({})
      end
    end,
  })
end

-- Загрузить конфигурацию
local function load_config()
  local config_path = config.config_file
  if vim.fn.filereadable(config_path) == 1 then
    local content = vim.fn.readfile(config_path)
    if #content > 0 then
      local ok, data = pcall(vim.json.decode, table.concat(content, "\n"))
      if ok then
        if data.default_device then
          config.default_device = data.default_device
        end
        if data.devices and type(data.devices) == "table" then
          config.devices = data.devices
        end
      end
    end
  end
end

-- Сохранить конфигурацию
local function save_config()
  local config_path = config.config_file
  local data = {
    default_device = config.default_device,
    devices = config.devices,
  }
  vim.fn.writefile({ vim.json.encode(data) }, config_path)
end

-- Получить текущее устройство (по умолчанию или выбранное)
local function get_current_device()
  if config.default_device then
    for _, device in ipairs(config.devices) do
      if device.name == config.default_device then
        return device
      end
    end
  end
  
  -- Если устройство по умолчанию не найдено, возвращаем первое доступное
  if #config.devices > 0 then
    return config.devices[1]
  end
  
  -- Если устройств нет, возвращаем дефолтное
  return { name = "default", ip = "192.168.1.100" }
end

-- Получить флаг устройства для команд ares
local function get_device_flag(device)
  if device and device.name then
    return { "-d", device.name }
  elseif device and device.ip then
    return { "-d", device.ip }
  else
    local current = get_current_device()
    if current.name then
      return { "-d", current.name }
    else
      return { "-d", current.ip }
    end
  end
end

-- Получить путь из neo-tree или текущего буфера
local function get_path_from_neotree()
  -- Пытаемся получить путь через neo-tree API
  local ok, sources = pcall(require, "neo-tree.sources")
  if ok and sources then
    local manager = sources.get_manager("filesystem")
    if manager then
      local state = manager.get_state()
      if state and state.tree then
        local node = state.tree:get_node()
        if node and node.path then
          -- Если это файл, возвращаем его директорию
          if vim.fn.isdirectory(node.path) == 1 then
            return node.path
          else
            return vim.fn.fnamemodify(node.path, ":p:h")
          end
        end
      end
    end
  end
  
  -- Альтернативный способ через neo-tree напрямую
  local ok2, neotree = pcall(require, "neo-tree")
  if ok2 and neotree then
    local state_manager = neotree.get_state_manager()
    if state_manager then
      local state = state_manager.get_state("filesystem")
      if state and state.tree then
        local node = state.tree:get_node()
        if node and node.path then
          if vim.fn.isdirectory(node.path) == 1 then
            return node.path
          else
            return vim.fn.fnamemodify(node.path, ":p:h")
          end
        end
      end
    end
  end
  
  -- Если не neo-tree, проверяем текущий буфер
  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  
  -- Если это файл, возвращаем его директорию
  if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
    return vim.fn.fnamemodify(bufname, ":p:h")
  end
  
  -- Или текущую директорию
  return vim.fn.getcwd()
end

-- Найти .ipk файл в директории
local function find_ipk_file(path, callback)
  local ipk_files = {}
  
  if vim.fn.isdirectory(path) == 1 then
    local files = vim.fn.readdir(path)
    for _, file in ipairs(files) do
      if file:match("%.ipk$") then
        table.insert(ipk_files, path .. "/" .. file)
      end
    end
  elseif path:match("%.ipk$") then
    if callback then
      callback(path)
    else
      return path
    end
    return
  end
  
  if #ipk_files == 0 then
    if callback then
      callback(nil)
    else
      return nil
    end
  elseif #ipk_files == 1 then
    if callback then
      callback(ipk_files[1])
    else
      return ipk_files[1]
    end
  else
    -- Если несколько файлов, предлагаем выбрать
    local choices = {}
    for i, file in ipairs(ipk_files) do
      table.insert(choices, vim.fn.fnamemodify(file, ":t"))
    end
    
    vim.ui.select(choices, {
      prompt = "Выберите .ipk файл:",
    }, function(choice, idx)
      if choice and idx and callback then
        callback(ipk_files[idx])
      elseif idx and not callback then
        return ipk_files[idx]
      end
    end)
  end
end

-- Выполнить команду и показать результат
local function run_command(cmd, args, callback)
  local full_cmd = vim.list_extend({ cmd }, args)
  local cmd_str = cmd .. " " .. table.concat(args, " ")
  vim.notify("Выполняется: " .. cmd_str, vim.log.levels.INFO)
  
  local output_lines = {}
  
  vim.fn.jobstart(full_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output_lines, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output_lines, "[ERROR] " .. line)
          end
        end
      end
    end,
    on_exit = function(_, code)
      if #output_lines > 0 then
        -- Показываем вывод в notify или можно открыть в буфере
        vim.notify(table.concat(output_lines, "\n"), code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
      end
      
      if code == 0 then
        vim.notify("Команда выполнена успешно: " .. cmd_str, vim.log.levels.INFO)
      else
        vim.notify("Команда завершилась с ошибкой (код: " .. code .. "): " .. cmd_str, vim.log.levels.ERROR)
      end
      
      if callback then
        callback(code == 0)
      end
    end,
  })
end

-- Установить приложение
local function install_app(path, device)
  if not path then
    path = get_path_from_neotree()
  end
  
  local device_flag = get_device_flag(device)
  
  find_ipk_file(path, function(ipk_file)
    if not ipk_file then
      -- Предлагаем выбрать файл вручную
      vim.ui.input({ prompt = "Введите путь к .ipk файлу: " }, function(input)
        if input and input ~= "" then
          if vim.fn.filereadable(input) == 1 then
            local args = vim.list_extend({}, device_flag)
            table.insert(args, input)
            run_command("ares-install", args)
          else
            vim.notify("Файл не найден: " .. input, vim.log.levels.ERROR)
          end
        end
      end)
      return
    end
    
    local args = vim.list_extend({}, device_flag)
    table.insert(args, ipk_file)
    run_command("ares-install", args)
  end)
end

-- Установить и запустить приложение
local function install_and_run(path, device)
  if not path then
    path = get_path_from_neotree()
  end
  
  local device_flag = get_device_flag(device)
  
  find_ipk_file(path, function(ipk_file)
    if not ipk_file then
      -- Предлагаем выбрать файл вручную
      vim.ui.input({ prompt = "Введите путь к .ipk файлу: " }, function(input)
        if input and input ~= "" then
          if vim.fn.filereadable(input) == 1 then
            local install_args = vim.list_extend({}, device_flag)
            table.insert(install_args, input)
            run_command("ares-install", install_args, function(success)
              if success then
                local app_id = input:match("([^/]+)%.ipk$"):gsub("%.ipk$", "")
                app_id = app_id:gsub("_[%d%.]+$", "")
                local launch_args = vim.list_extend({}, device_flag)
                table.insert(launch_args, app_id)
                run_command("ares-launch", launch_args)
              end
            end)
          else
            vim.notify("Файл не найден: " .. input, vim.log.levels.ERROR)
          end
        end
      end)
      return
    end
    
    local install_args = vim.list_extend({}, device_flag)
    table.insert(install_args, ipk_file)
    run_command("ares-install", install_args, function(success)
      if success then
        -- Используем ares-launch для запуска
        -- app_id обычно извлекается из appinfo.json внутри ipk, но можно попробовать из имени файла
        local app_id = ipk_file:match("([^/]+)%.ipk$"):gsub("%.ipk$", "")
        -- Убираем версию если есть (например: app_1.0.0.ipk -> app)
        app_id = app_id:gsub("_[%d%.]+$", "")
        local launch_args = vim.list_extend({}, device_flag)
        table.insert(launch_args, app_id)
        run_command("ares-launch", launch_args)
      end
    end)
  end)
end

-- Инспектировать приложение
local function inspect_app(device)
  local device_flag = get_device_flag(device)
  run_command("ares-inspect", device_flag)
end

-- Подключиться через novacom
local function connect_novacom(device)
  local current_device = device or get_current_device()
  local device_name = current_device.name or current_device.ip
  -- Для novacom shell нужно открыть терминал
  vim.cmd("terminal ares-novacom -d " .. device_name .. " shell")
end

-- Выбрать устройство из списка
local function select_device(callback)
  if #config.devices == 0 then
    -- Если устройств нет, обновляем список
    get_ares_devices(function(devices)
      config.devices = devices
      save_config()
      if #devices == 0 then
        vim.notify("Устройства не найдены. Убедитесь, что ares настроен.", vim.log.levels.WARN)
        if callback then
          callback(nil)
        end
      elseif #devices == 1 then
        if callback then
          callback(devices[1])
        end
      else
        local choices = {}
        for _, device in ipairs(devices) do
          local label = device.name
          if device.ip and device.ip ~= "" then
            label = label .. " (" .. device.ip .. ")"
          end
          if device.name == config.default_device then
            label = label .. " [по умолчанию]"
          end
          table.insert(choices, label)
        end
        vim.ui.select(choices, {
          prompt = "Выберите устройство:",
        }, function(choice, idx)
          if choice and idx and callback then
            callback(devices[idx])
          elseif callback then
            callback(nil)
          end
        end)
      end
    end)
  else
    if #config.devices == 1 then
      if callback then
        callback(config.devices[1])
      end
    else
      local choices = {}
      for _, device in ipairs(config.devices) do
        local label = device.name
        if device.ip and device.ip ~= "" then
          label = label .. " (" .. device.ip .. ")"
        end
        if device.name == config.default_device then
          label = label .. " [по умолчанию]"
        end
        table.insert(choices, label)
      end
      vim.ui.select(choices, {
        prompt = "Выберите устройство:",
      }, function(choice, idx)
        if choice and idx and callback then
          callback(config.devices[idx])
        elseif callback then
          callback(nil)
        end
      end)
    end
  end
end

-- Создать модальное окно
local function create_modal_window()
  local width = 70
  local height = 25
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })
  
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_option(buf, "filetype", "webos")
  
  local current_device = get_current_device()
  local device_display = current_device.name or current_device.ip or "не выбрано"
  if current_device.name == config.default_device then
    device_display = device_display .. " [по умолчанию]"
  end
  
  local lines = {
    "╔══════════════════════════════════════════════════════════════════╗",
    "║                    WebOS TV Management                          ║",
    "╠══════════════════════════════════════════════════════════════════╣",
    "║                                                                  ║",
    "║  Текущее устройство: " .. string.format("%-45s", device_display) .. "║",
    "║                                                                  ║",
    "║  Доступные команды:                                              ║",
    "║                                                                  ║",
    "║  1. Установить приложение (ares-install)                         ║",
    "║  2. Установить и запустить (ares-install + ares-launch)         ║",
    "║  3. Инспектировать (ares-inspect)                               ║",
    "║  4. Подключиться (ares-novacom shell)                           ║",
    "║                                                                  ║",
    "║  Управление устройствами:                                       ║",
    "║                                                                  ║",
    "║  5. Выбрать устройство                                          ║",
    "║  6. Установить устройство по умолчанию                          ║",
    "║  7. Обновить список устройств                                    ║",
    "║                                                                  ║",
    "║  Для конкретного устройства:                                    ║",
    "║                                                                  ║",
    "║  8. Установить на устройство                                     ║",
    "║  9. Установить и запустить на устройстве                        ║",
    "║  0. Инспектировать устройство                                  ║",
    "║  c. Подключиться к устройству                                  ║",
    "║                                                                  ║",
    "║  Нажмите цифру/букву или q для выхода                            ║",
    "║                                                                  ║",
    "╚══════════════════════════════════════════════════════════════════╝",
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  -- Keymaps для модального окна
  local keymaps = {
    ["1"] = function()
      vim.api.nvim_win_close(win, true)
      local path = get_path_from_neotree()
      install_app(path)
    end,
    ["2"] = function()
      vim.api.nvim_win_close(win, true)
      local path = get_path_from_neotree()
      install_and_run(path)
    end,
    ["3"] = function()
      vim.api.nvim_win_close(win, true)
      inspect_app()
    end,
    ["4"] = function()
      vim.api.nvim_win_close(win, true)
      connect_novacom()
    end,
    ["5"] = function()
      vim.api.nvim_win_close(win, true)
      select_device(function(device)
        if device then
          vim.notify("Выбрано устройство: " .. (device.name or device.ip), vim.log.levels.INFO)
        end
      end)
    end,
    ["6"] = function()
      vim.api.nvim_win_close(win, true)
      select_device(function(device)
        if device then
          config.default_device = device.name
          save_config()
          vim.notify("Устройство установлено по умолчанию: " .. device.name, vim.log.levels.INFO)
        end
      end)
    end,
    ["7"] = function()
      vim.api.nvim_win_close(win, true)
      vim.notify("Обновление списка устройств...", vim.log.levels.INFO)
      get_ares_devices(function(devices)
        config.devices = devices
        save_config()
        vim.notify("Найдено устройств: " .. #devices, vim.log.levels.INFO)
      end)
    end,
    ["8"] = function()
      vim.api.nvim_win_close(win, true)
      select_device(function(device)
        if device then
          local path = get_path_from_neotree()
          install_app(path, device)
        end
      end)
    end,
    ["9"] = function()
      vim.api.nvim_win_close(win, true)
      select_device(function(device)
        if device then
          local path = get_path_from_neotree()
          install_and_run(path, device)
        end
      end)
    end,
    ["0"] = function()
      vim.api.nvim_win_close(win, true)
      select_device(function(device)
        if device then
          inspect_app(device)
        end
      end)
    end,
    ["c"] = function()
      vim.api.nvim_win_close(win, true)
      select_device(function(device)
        if device then
          connect_novacom(device)
        end
      end)
    end,
    ["q"] = function()
      vim.api.nvim_win_close(win, true)
    end,
    ["<Esc>"] = function()
      vim.api.nvim_win_close(win, true)
    end,
  }
  
  for key, func in pairs(keymaps) do
    vim.keymap.set("n", key, func, { buffer = buf, nowait = true })
  end
  
  -- Фокус на окно
  vim.api.nvim_set_current_win(win)
end

-- Открыть модальное окно
function M.open()
  load_config()
  -- Обновляем список устройств при открытии, если список пуст
  if #config.devices == 0 then
    get_ares_devices(function(devices)
      config.devices = devices
      save_config()
      create_modal_window()
    end)
  else
    create_modal_window()
  end
end

-- Обновить список устройств
function M.refresh_devices()
  load_config()
  vim.notify("Обновление списка устройств...", vim.log.levels.INFO)
  get_ares_devices(function(devices)
    config.devices = devices
    save_config()
    vim.notify("Найдено устройств: " .. #devices, vim.log.levels.INFO)
  end)
end

-- Выбрать устройство по умолчанию
function M.set_default_device()
  load_config()
  select_device(function(device)
    if device then
      config.default_device = device.name
      save_config()
      vim.notify("Устройство установлено по умолчанию: " .. device.name, vim.log.levels.INFO)
    end
  end)
end

-- Прямые функции для быстрого доступа (используют устройство по умолчанию)
function M.install()
  load_config()
  local path = get_path_from_neotree()
  install_app(path)
end

function M.install_and_run()
  load_config()
  local path = get_path_from_neotree()
  install_and_run(path)
end

function M.inspect()
  load_config()
  inspect_app()
end

function M.connect()
  load_config()
  connect_novacom()
end

-- Функции для работы с конкретным устройством
function M.install_to_device()
  load_config()
  select_device(function(device)
    if device then
      local path = get_path_from_neotree()
      install_app(path, device)
    end
  end)
end

function M.install_and_run_to_device()
  load_config()
  select_device(function(device)
    if device then
      local path = get_path_from_neotree()
      install_and_run(path, device)
    end
  end)
end

function M.inspect_device()
  load_config()
  select_device(function(device)
    if device then
      inspect_app(device)
    end
  end)
end

function M.connect_to_device()
  load_config()
  select_device(function(device)
    if device then
      connect_novacom(device)
    end
  end)
end

return M
