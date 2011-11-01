# Install #
Inside the project folder run:

          npm install

This installs all necessary modules. If you add new modules to this project, please make sure to add your dependencies to packages.json
You can then start the server with:

        socketstream start
        
And enter the console with:

        socketstream console


This Code is just a draft most of the stuff is not implemented yet.
I started to create a DJ Model in Backbone that by now works with a ServerSide
Redis Store. But is planed to work on both the Server and the Client.

By Now you can use 

      SS.server.dj.create({name: "a0n", email: "bla@bla.xyz", pw: "insecure"}, function(response) {}) 
      SS.server.dj.authenticate({email: "a0n", pw: "insecure"})

to create a new DJ via Websockets.
The Global SS variable is available on client and server. you can access it from the socketstream console AND from the console of your Browser


On the Socketstream Console you can Play with the DJ Backbone Model by requiring it. This model, by now, is only testet on the server side.
  


      SS.require("models/dj.coffee")
      new_dj = new SS.models.dj({name: "a0n", email: "bla@bla.xyz", pw: "insecure"})
      new_dj.save({}, {error: function(model, err) {}, success: function(model, resp){} })


# Blip rewrite doc #
## App Focus ##
* To provide a fully opensource alternative to the blip.fm service
* provide an api to register services global services  
* provide an api to register dj user services
* provide a webapi search from the biggest video and audio streaming sites:
    * soundcloud
    * myspace
    *amazon
    * youtube
    * vimeo
    * dailymotion
    * mixcloud

## Data ##
  DJs have a global feed. This feed includes their own blips and their account activity
   
  Account activity includes

* new dj listenings
* probs on songs
* changes to blips
  
## User Actions ##
  
*  DJs have a feed of blips they have received probs for
*  DJs can subscribe to other DJs
*  DJs get all blips from other DJs into their radiostream
*  DJs can give probs to other djs blips
*  DJs can reference other djs in the bliptext
*  DJs can reference to # tags in the bliptext
*  DJs can search and reference lyrics to the blip
  


## Howto create the data structure with redis. some examples for controller code ##

        Create Blip
          if media exists
            add blip to media:<<id>>.blips
          else
            create media with unique id
            add media_id to medias set if the object exists increase the score
            add blip to media:<<id>>.blips with the current date as score
  
          Save blip with unique id
          increase the blip count in dj:blip_count of creating dj
          add blip to .blip_list of creating dj
          publish blip to .changes of creating dj
          save publish to .activity of creating dj
  
          if bliptext includes tags
            add tag to dj:<<id>>.tags set or increase score
            add tag to tags set or increase score
            add blip_id to tags:<<tagname>>.blips
            publish blip to tags:<<tagname>>.changes
  
          if dj name is inside blip text
            add dj_id to dj:send_replies or increase score
            add dj_id to dj:<<id>>.send_replies or increase score
            for every dj name
              add dj_id to dj:received_replies or increase scores
              add dj_id to dj:<<id>>.received_replies or increase scores
              publish blip to dj:<<id>>.changes as a received blip
              save blip to dj:<<id>>.activity as a received blip
 
        Delete Blip
          if blip has a reblip_of attribute
            remove blip_id from blip:<<reblip_of>>.reblips

          remove blip from media:<<id>>.blips
          Delete blip hash with unique id
          decrease the blip count in dj:blip_count of creating dj
          remove blip to .blip_list of creating dj
          publish blip_change to .changes of creating dj
          save publish to .activity of creating dj

          if bliptext includes tags
            remove tag to dj:<<id>>.tags set or decrease score
            remove tag from tags set or decrease score
            remove blip_id to tags:<<tagname>>.blips
            publish blip_change to tags:<<tagname>>.changes

          if dj name is inside blip text
            remove dj_id from dj:send_replies or decrease score
            remove dj_id from dj:<<id>>.send_replies or decrease score
            for every dj name
              remove dj_id to dj:received_replies or decrease scores
              remove dj_id to dj:<<id>>.received_replies or decrease scores
              publish blip_change to dj:<<id>>.changes as a removed blip
              save blip_change to dj:<<id>>.activity as a received blip

        Give Probs to a Blip
          add "prob giving dj" id to blip:<<id>>.probs with current date as score
          add blip id to the giving djs .given_probs list with date as score
          add blip id to the receving djs .received_probs list with date as score
          add or increase the receving DJ-ID in dj.received_prob_count
          add or increase the giving DJ-ID in dj.given_prob_count
          add prob as activity to the .activity of both djs (one for receiving one for giving)
          publish prob activity to the .changes of both users
          publish prob activity to the tag name .changes if tags are present

        Follow a User
          Add the id of the dj to follow to the .following list of the user that follows
          Add the following event to the following djs .activity and publish through .changes
          Add the id of the dj that follows to the .followers list of the dj that he follows
          Add the getting followed event to the followed djs .activity and publish through .changes
  
        Unfollow a User
          Remove the id of the dj to follow to the .following list of the user that follows
          Add the unfollowing event to the following djs .activity and publish through .changes
          Remove the id of the dj that follows to the .followers list of the dj that he follows
          Add the getting unfollowed event to the followed djs .activity and publish through .changes


## Redis Structure ##
  
          dj:blip_count              || Sorted Set of dj_ids                 BLIP_COUNT - DJ_ID
          dj:received_prob_count     || Sorted Set of dj_ids                 PROB_COUNT - DJ_ID
          dj:given_prob_count         || Sorted Set of dj_ids                 PROB_COUNT - DJ_ID
          dj:send_replies            || Sorted Set of dj_ids                 SEND_COUNT - DJ_ID
          dj:received_replies        || Sorted Set of dj_ids                 RECEIVED_COUNT - DJ_ID
    
          dj:<<id>>                   || Hash {:name, :email, :password}
          dj:<<id>>.activity          || Sorted Set of activity json objects   DATE - ACTIVITY
          dj:<<id>>.changes           || Pub Sub Channel for this Users changes
          dj:<<id>>.tags              || Sorted Set of tagnames used in djs blips COUNT_USED - TAG
          dj:<<id>>.followers         || Sorted Set of DJs how are Followers   DATE - DJ_ID
          dj:<<id>>.following         || Sorted Set of DJs Following           DATE - DJ_ID
          dj:<<id>>.given_probs       || Sorted Set of blip_ids                DATE - BLIP_ID 
          dj:<<id>>.received_probs    || Sorted Set of blip_ids                DATE - BLIP_ID
          dj:<<id>>.send_replies      || Sorted Set of blip_ids                DATE - BLIP_ID
          dj:<<id>>.received_replies  || Sorted Set of blip_ids                DATE - BLIP_ID
          dj:<<id>>.blip_list         || Sorted Set of blip_ids                DATE - BLIP_ID
    
          blip:<<id>>                 || Hash {:text, :user_id, :media_id, :timestamps, :reblip_of}
          blip:<<id>>.probs           || Sorted Set of dj_ids                  DATE - DJ_ID
          blip:<<id>>.reblips         || Sorted Set of blip_ids                REBLIP COUNT - BLIP_ID
    
          tags                        || Sorted Set of used_tags               TAG_COUNT - TAG
          tag:<<tagname>>.blips       || Sorted Set of blip_ids                DATE - BLIP_ID
          tag:<<tagname>>.djs         || Sorted Set of dj_ids                  DATE - DJ_ID
          tag:<<tagname>>.changes     || Pub Sub Channel for all blips with this tag
          medias                      || Sorted Set of media_ids               BLIP_COUNT - ID
          medias:<<id>>               || Hash {:type, :source, :metadata => {:title, :artist, :album, :release_date etc}}
          medias:<<id>>.blips         || Sorted Set of blip_ids                DATE - ID