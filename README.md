<img src="https://github.com/raegen/chat-lfg/raw/master/logo.png" width="100px" height="100px" />

# Chat LFG

**Filter** and **display** aggregated chat messages from channels commonly used for **LFG** (_LookingForGroup_, _World_, _General_). Instead of manually hunting through swarms of non-relevant postings, Chat LFG allows you to search for and display only the ones of interest. Just set the desired search term (_raid/dungeon/quest/mob_ name, _role_ etc) and the matching postings will be printed to your chat window, as an interactive line with linked author, what he's looking for and how many, for easy contact:
![Interactive chat line](https://i.imgur.com/oIgaIsZ.jpg "Interactive chat line")

# Usage

#### Start looking for group: `/clfg lfg SEARCHTERM`
#### Start looking for members: `/clfg lfm SEARCHTERM`
#### Stop current search: `/clfg stop`

### To use context menu **Sign up for instance group** feature (whispers the posting author with your role, class and level if applicable) you need to set your role. It is done by the following command and once set, it will persist through sessions until you change it again:
#### Set role: `/clfg role Tank/Healer/DPS`

# Examples

`/clfg lfg ubrs`

`/clfg lfm brd tank/dps`

`/clfg role tank`

# TODO

- [x] Advanced message parsing (roles,  number of spots etc) // _Additional improvements are planed_
- [x] Role-based filtering
- [ ] Support for group creation (parse LFG, apart from LFM, messages, check player role, requirements, automatic invitate)
- [ ] GUI

### **NOTICE**: _This is a work in progress, there will be frequent updates/hotfixes for a while so please, bear with me_
