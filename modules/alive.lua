function alive()
    while true do
        redstone.setOutput(kristed.config.redstone, true)
        os.sleep(2)
        redstone.setOutput(kristed.config.redstone, false)
        os.sleep(2)
    end
end

return alive