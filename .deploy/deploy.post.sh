DOCROOT=/tmp/<%tag%>/deploy_tester
DEP_ENV="<%tag%>"
LOCAL_BIN_DIR="/usr/local/bin/"

###########################################################################
#       COMMON DIRECTIVES
###########################################################################
# START COMMON
#Copy /usr/share/install to final destination
if [ ! -e ${DOCROOT}]; then
cd -p ${DOCROOT}/..
rm -rf deploy_tester
fi
mkdir -p ${DOCROOT}
%{__mv} /usr/share/parta/labs ${DOCROOT}


##########################################################################
#      Send email when deployed succesfully
##########################################################################
host=`/bin/hostname`
cat <<EOF >/var/tmp/deploy_email_%{name}.php
<?php
function build_url_query(\$array, \$first_is_qm=true, \$preceeding="")
{
    \$qs = "";
    \$query_array = array();
    foreach(\$array as \$k=>\$v)
    {
        if (\$preceeding == "")
            \$query_array[] = (is_array(\$v) ?
            build_url_query(\$v, false, \$preceeding.\$k):
            \$k."=".urlencode(\$v));
        else{
            \$query_array[] = (is_array(\$v) ?
            build_url_query(\$v, false, \$preceeding."[".\$k."]"):
            \$preceeding."[".\$k."]=".urlencode(\$v));
        }
    }
    return implode("&",\$query_array);
}
\$post = array(
    "project" => "%{name}",
    "lang" => "en-us",
    "environment" => 1,
    "data" => array(
        "to"        => array("marc.henri@engagementlabs.com"),
        "from"      => array("dev@engagementlabs.com"),
        "subject"   => "Deployed %{name} on <%tag%>",
        "mime_type" => "text/plain",
        "reply_to"  => "dev@engagementlabs.com",
        "message"   => "Deployed %{name} on <%tag%>\n\nPackage:%{name}-%{version}-%{release}\nVersion:%{version}-<%build%>\nGit Rev Num: <%svn_rev_num%>\nHostname:$host\n\n\n\nThis was an automated email, a reply is unecessary."
    )
);
\$post = build_url_query(\$post);


//email message to admin
\$handle = curl_init();
curl_setopt(\$handle, CURLOPT_URL, "http://notification.partadialogue.com/notification/send");
curl_setopt(\$handle, CURLOPT_VERBOSE, 0);
curl_setopt(\$handle, CURLOPT_HEADER, 0);
curl_setopt(\$handle, CURLOPT_POST, 1);
curl_setopt(\$handle, CURLOPT_RETURNTRANSFER, 1);
curl_setopt(\$handle, CURLOPT_POSTFIELDS, \$post);
curl_exec(\$handle);
EOF
/usr/bin/php /var/tmp/deploy_email_%{name}.php 2>> /dev/null >> /dev/null
