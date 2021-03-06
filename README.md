# Redmine Dashboard - a better view for your projects

Redmine Dashboard is one group of views that permit to you visualize your projects and your team better.

## Installation

### New version

The Dashboard plugin requires Redmine 1.2.0 to be installed. Redmine 1.1.x is known to work but is not supported. For more information on Redmine and how to install it, please visit the [official Redmine website](http://www.redmine.org/). 

    $ git clone git://github.com/ebc/redmine_dashboard.git
    $ copy plugins/redmine_dashboard $REDMINE_HOME$/vendor/plugins/redmine_dashboard
    
[![Preview of Redmine Dashboard - New version][preview]][blog]


### Old version

The Dashboard plugin requires Redmine 1.2.0 to be installed and [Backlogs](http://www.redminebacklogs.net/en/installation.html) plugin because there are some jqPlot Charts dependencies.

    $ cd $REDMINE_HOME$/vendor/plugins/
    $ git clone git://github.com/ebc/redmine_dashboard.git

## LICENSE

This plugin is released under the GPL v2 license. See LICENSE for more information.

[blog]: http://blog.danielnegri.com/
[preview]: https://github.com/ebc/redmine_dashboard/raw/master/images/preview.png

