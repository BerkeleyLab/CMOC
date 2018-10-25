# Install kivy on debian stretch, version 1.9.1 required
    apt-get install python-kivy

# Optional: check kivy version:
    python -c "import kivy"

# Install kivy garden
    pip install kivy-garden

# Install matplotlib package
    garden install matplotlib

# Optional: Upgrade matplotlib package
    garden install --upgrade matplotlib

# Tips for udp port fowarding if FPGA is in private network:
    # 192.168.1.100 : target FPGA IP
    # 128.3.130.117 : forwarding server IP
    iptables -A FORWARD -i eth0 -p udp -m udp -d 192.168.1.100 --dport 3000 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -t nat -A PREROUTING -p udp -m udp -i eth0 -d 128.3.130.117 --dport 3000 -j DNAT --to-destination 192.168.1.100:3000
    # In case of using multiple Network Cards, say eth0 and eth1. You will
    # have to enable ip forwarding. On a Debian like system:
    echo 1 > /proc/sys/net/ipv4/ip_forward

# Build Andriod APK
    https://kivy.org/docs/guide/packaging-android.html
    http://buildozer.readthedocs.org/en/latest/installation.html
