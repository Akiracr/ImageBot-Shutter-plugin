#! /usr/bin/env perl
###################################################
#
#  Copyright (C) 2013 Max Méndez <maxmv@maxmendez.net>
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Shutter is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
###################################################

package ImageBot;

use lib $ENV{'SHUTTER_ROOT'}.'/share/shutter/resources/modules';

use utf8;
use strict;
use POSIX qw/setlocale/;
use Locale::gettext;
use Glib qw/TRUE FALSE/;
use Data::Dumper;

use Shutter::Upload::Shared;
our @ISA = qw(Shutter::Upload::Shared);

my $d = Locale::gettext->domain("shutter-upload-plugins");
$d->dir( $ENV{'SHUTTER_INTL'} );

my %upload_plugin_info = (
   'module' => "ImageBot",
   'url' => "http://www.imagebot.net/",
   'registration' => "http://www.imagebot.net/user/register",
   'description' => $d->get("Upload screenshots to ImageBot"),
   'supports_anonymous_upload' => TRUE,
   'supports_authorized_upload' => TRUE,
);

binmode( STDOUT, ":utf8" );
if ( exists $upload_plugin_info{$ARGV[ 0 ]} ) {
    print $upload_plugin_info{$ARGV[ 0 ]};
    exit;
}


#don't touch this
sub new {
    my $class = shift;

    #call constructor of super class (host, debug_cparam, shutter_root, gettext_object, main_gtk_window, ua)
    my $self = $class->SUPER::new( shift, shift, shift, shift, shift, shift );
    bless $self, $class;
    return $self;
}

sub init {
    my $self = shift;

    use JSON;
    use LWP::UserAgent;
    use HTTP::Request::Common;

    return TRUE;
}

sub upload {
    my ( $self, $upload_filename, $username, $password ) = @_;

    #store as object vars
    $self->{_filename} = $upload_filename;
    $self->{_username} = $username;
    $self->{_password} = $password;

    utf8::encode $upload_filename;
    utf8::encode $password;
    utf8::encode $username;

    #examples related to the sub 'init'
    my $json_coder = JSON::XS->new;

    my $browser = LWP::UserAgent->new(
        'timeout' => 20,
        'keep_alive' => 10,
        'env_proxy' => 1,
    );

    my $client = LWP::UserAgent->new(
      'timeout' => 30,
      'keep_alive' => 10,
      'env_proxy' => 1,
    );

    eval{

      my %params = (
        'file' => [$upload_filename],
        'api_username' => $username,
        'api_password' => $password,
      );

      my @params = (
        "http://www.imagebot.net/upload_img_api",
        'Content_Type' => 'multipart/form-data',
        'Content' => [%params]
      );
      
      my $req = HTTP::Request::Common::POST(@params);
      push @{ $client->requests_redirectable }, 'POST';
      my $rsp = $client->request($req);

      #convert JSON
      my $ref = decode_json($rsp->content);

      unless(defined $ref->{'error'}){

        foreach (keys %{$ref}){
          $self->{_links}->{$_} = $ref->{$_};
        }
        #set status (success)
        $self->{_links}{'status'} = 200;        
      }else{
        $self->{_links}{'status'} = $ref->{'error'};
      }
    
    };
    if($@){
      $self->{_links}{'status'} = $@;
    }
  
    #and return links
    return %{ $self->{_links} };
}


1;

