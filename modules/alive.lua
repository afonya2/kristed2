function alive()
    while true do
        redstone.setOutput(kristed.config.redstone, true)
        os.sleep(1)
        redstone.setOutput(kristed.config.redstone, false)
        os.sleep(1)
    end
end

return alive