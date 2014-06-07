-- Reanmachine TekOS
-- APP: Github

-- Constants
asset_type_app = "app"
asset_type_lib = "lib"

github_content_path = "https://raw.githubusercontent.com"

-- Functions

function get_asset_remote_path(name, asset_type)
	if asset_type == asset_type_app then
		return name..".app.lua"
	end

	if asset_type == asset_type_lib then
		return name..".lib.lua"
	end

	error("Unknown asset type: "..asset_type)
end

function get_asset_target_path(name, asset_type)
	if asset_type == asset_type_app then
		return "/"..name
	end

	if asset_type == asset_type_lib then
		return "/libs/"..name
	end

	error("Unknown asset type: "..asset_type)
end

---
-- Downloads a file from a github project
-- @param project  The project identity (eg Reanmachine/something)
-- @param revision  The revision to get (if none, will use 'master')
-- @param file  The file to download (relative path from project root)
-- @param dest  The destination file to download it into locally
function get_github_resource(project, revision, file)

	if not project then error("project cannot be nil") end
	if type(project) ~= "string" then error("project must be a string") end

	-- Default the revision to master
	if not revision then
		revision = "master"
	end

	local project_content_path = github_content_path.."/"..project
	local project_revision_path = project_content_path.."/"..revision
	local project_file_path = project_revision_path.."/"..file

	local web_result = http.get(project_file_path)

	if not web_result then
		return {found=false, code=0, data=""}
	end

	local found = web_result.getResponseCode() == 200

	return {found=found, code=web_result.getResponseCode(), data=web_result.readAll()}

end

function get_asset(project, revision, name, asset_type)

	local target_file = get_asset_remote_path(name, asset_type)
	local result = get_github_resource(project, revision, target_file)

	if not result or not result.found then
		local reason = nil

		if result.code == 404 then reason = "File not Found" end
		if result.code == 403 then reason = "Forbidden" end

		local message = string.format(
			"Unable to Retrieve %s '%s' from repository '%s'",
			asset_type,
			name,
			project)

		if not reason then
			print(message..": "..reason)
		else
			print(message)
		end

		return false
	end

	local target_path = get_asset_target_path(name, asset_type)
	local target_output = fs.open(target_path, "w")
	target_output.write(result.data)
	target_output.flush()
	target_output.close()

	print(string.format(
		"%s '%s' downloaded successfully to '%s'",
		asset_type,
		name,
		target_path))

end

function usage()
	print("github <project> <type> <name>")
	print("  <project> - The GitHub User/Repository path of the project. (eg: mojang/minecraft)")
	print("  <type>    - 'app' or 'lib' to denote package type.")
	print("  <name>    - The name relative to the root of the project.")
end

-- Application Logic

local arg = { ... }

if #arg < 3 then
	print("ERROR: not enough arugments")
	usage()
	exit()
end

local project = arg[1]
local asset_type = arg[2]
local asset_name = arg[3]

if asset_type == asset_type_app then
	print(string.format("Downloading App '%s' from '%s'...", asset_name, project))
elseif asset_type == asset_type_lib then
	print(string.format("Downloading Lib '%s' from '%s'...", asset_name, project))
else
	print("ERROR: invalid asset type '"..asset_type.."'")
	usage()
	exit()
end

get_asset(project, nil, asset_name, asset_type)