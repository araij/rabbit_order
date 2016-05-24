Rabbit Order
============

- This is an implementation of an algorithm proposed in the following paper:
    - J. Arai, H. Shiokawa, T. Yamamuro, M. Onizuka, and S. Iwamura.
      Rabbit Order: Just-in-time Parallel Reordering for Fast Graph Analysis.
      IEEE International Parallel and Distributed Processing Symposium (IPDPS),
      2016.
- Please read `license.txt` before reading or using the files.
- Note that some graph datasets are already reordered, and so Rabbit Order will
  not show significant performance improvement on those graphs.
    - For example, [Laboratory for Web Algorithmics](http://law.di.unimi.it/)
      reorders graphs using Layered Label Propagation.
    - Web graphs are sometimes reordered by URL. This ordering is known to show
      good locality.
- Now the files are a bit dirty. They will be updated soon. -- May 24, 2016


How to use
----------

`demo/reorder.cc` is a sample program to reorder a graph by using Rabbit Order.
Try `make` in the `demo/` directory and run the program.

### Requirements

- g++ (4.9.2)
- Boost C++ library (1.58.0)
- libnuma (2.0.9)
- libtcmalloc\_minimal in google-perftools (2.1)

Numbers in each parenthesis are the oldest versions that we used to test this
program.

