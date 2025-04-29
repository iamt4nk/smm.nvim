---@alias Request_Type
---| 'GET'
---| 'POST'
---| 'PUT'

---@alias Get_Request {request_name: string, url: string, headers: table|nil, query:table|nil}
---@alias Post_Request {request_name: string, url: string, headers: table|nil, query: table|nil, body: table|string|nil}
---@alias Put_Request {request_name: string, url: string, headers: table|nil, query: table|nil, body: table|string|nil}

---@alias Retry_Opts {request_type: Request_Type, request_opts: Get_Request|Post_Request|Put_Request, callback: fun(response_body, response_headers, status_code)}
